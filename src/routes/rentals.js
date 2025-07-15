/**
 * Rental management routes for JitsuFlow API
 * レンタル管理API - 道着・用具貸し出し
 */

import { Router } from 'itty-router';
import { corsHeaders } from '../middleware/cors';
import { requireAdmin } from '../middleware/auth';

const router = Router();

// レンタル商品一覧取得
router.get('/api/dojo-mode/:dojoId/rentals', async (request) => {
  try {
    const { dojoId } = request.params;
    const url = new URL(request.url);
    const category = url.searchParams.get('category');
    const status = url.searchParams.get('status') || 'available';

    let query = `
      SELECT 
        r.*,
        COUNT(rt.id) as active_rentals,
        COUNT(CASE WHEN rt.status = 'overdue' THEN 1 END) as overdue_count
      FROM rentals r
      LEFT JOIN rental_transactions rt ON r.id = rt.rental_id AND rt.status = 'active'
      WHERE r.dojo_id = ?
    `;

    const params = [dojoId];

    if (category && category !== 'all') {
      query += ' AND r.item_type = ?';
      params.push(category);
    }

    if (status) {
      query += ' AND r.status = ?';
      params.push(status);
    }

    query += ' GROUP BY r.id ORDER BY r.item_type, r.item_name';

    const rentals = await request.env.DB.prepare(query).bind(...params).all();

    return new Response(JSON.stringify({
      rentals: rentals.results
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Get rentals error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to get rentals',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// レンタル商品作成（管理者のみ）
router.post('/api/dojo-mode/:dojoId/rentals', async (request) => {
  try {
    // 管理者権限チェック
    const adminCheck = requireAdmin(request);
    if (adminCheck) return adminCheck;

    const { dojoId } = request.params;
    const {
      item_type,
      item_name,
      size,
      color,
      condition = 'good',
      total_quantity,
      rental_price,
      deposit_amount = 0,
      barcode,
      notes
    } = await request.json();

    // バリデーション
    if (!item_type || !item_name || !total_quantity || !rental_price) {
      return new Response(JSON.stringify({
        error: 'Missing required fields',
        message: '商品種類、商品名、数量、レンタル料は必須です'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // レンタル商品作成
    const result = await request.env.DB.prepare(`
      INSERT INTO rentals (
        dojo_id, item_type, item_name, size, color, condition,
        total_quantity, available_quantity, rental_price, deposit_amount,
        barcode, notes, status, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      dojoId,
      item_type,
      item_name,
      size,
      color,
      condition,
      total_quantity,
      total_quantity, // 初期は全て利用可能
      rental_price,
      deposit_amount,
      barcode,
      notes,
      'available',
      new Date().toISOString(),
      new Date().toISOString()
    ).run();

    // 作成された商品を取得
    const rental = await request.env.DB.prepare(
      'SELECT * FROM rentals WHERE id = ?'
    ).bind(result.meta.last_row_id).first();

    return new Response(JSON.stringify({
      message: 'Rental item created successfully',
      rental
    }), {
      status: 201,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Create rental error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to create rental item',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// レンタル開始
router.post('/api/rentals/:rentalId/rent', async (request) => {
  try {
    const { rentalId } = request.params;
    const {
      user_id,
      return_due_date,
      rental_days = 7,
      deposit_paid,
      notes
    } = await request.json();

    // レンタル商品の確認
    const rental = await request.env.DB.prepare(`
      SELECT * FROM rentals 
      WHERE id = ? AND status = 'available' AND available_quantity > 0
    `).bind(rentalId).first();

    if (!rental) {
      return new Response(JSON.stringify({
        error: 'Rental not available',
        message: 'レンタル商品が利用できません'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // ユーザー確認
    const user = await request.env.DB.prepare(
      'SELECT * FROM users WHERE id = ?'
    ).bind(user_id).first();

    if (!user) {
      return new Response(JSON.stringify({
        error: 'User not found',
        message: 'ユーザーが見つかりません'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // レンタル期間計算
    const rentalDate = new Date();
    const returnDueDate = return_due_date ?
      new Date(return_due_date) :
      new Date(Date.now() + rental_days * 24 * 60 * 60 * 1000);

    // 料金計算
    const rentalFee = rental.rental_price * rental_days;
    const depositAmount = deposit_paid || rental.deposit_amount;
    const totalPaid = rentalFee + depositAmount;

    // レンタル取引作成
    const transactionResult = await request.env.DB.prepare(`
      INSERT INTO rental_transactions (
        rental_id, user_id, rental_date, return_due_date,
        rental_fee, deposit_paid, total_paid, status, notes, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      rentalId,
      user_id,
      rentalDate.toISOString(),
      returnDueDate.toISOString(),
      rentalFee,
      depositAmount,
      totalPaid,
      'active',
      notes,
      new Date().toISOString()
    ).run();

    // 在庫更新
    await request.env.DB.prepare(`
      UPDATE rentals 
      SET available_quantity = available_quantity - 1,
          updated_at = ?
      WHERE id = ?
    `).bind(new Date().toISOString(), rentalId).run();

    // 支払い記録作成
    await request.env.DB.prepare(`
      INSERT INTO payments (
        payment_type, amount, tax_amount, total_amount, 
        dojo_id, user_id, status, payment_method,
        description, payment_date, paid_at, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      'rental_fee',
      rentalFee,
      0, // レンタル料は非課税
      totalPaid,
      rental.dojo_id,
      user_id,
      'completed',
      'cash', // デフォルト現金
      `レンタル: ${rental.item_name}`,
      new Date().toISOString(),
      new Date().toISOString(),
      new Date().toISOString()
    ).run();

    return new Response(JSON.stringify({
      message: 'Rental started successfully',
      transaction_id: transactionResult.meta.last_row_id,
      rental_fee: rentalFee,
      deposit_paid: depositAmount,
      total_paid: totalPaid,
      return_due_date: returnDueDate.toISOString()
    }), {
      status: 201,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Start rental error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to start rental',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// レンタル返却
router.patch('/api/rental-transactions/:transactionId/return', async (request) => {
  try {
    const { transactionId } = request.params;
    const {
      condition_on_return = 'good',
      damage_fee = 0,
      late_fee = 0,
      notes
    } = await request.json();

    // レンタル取引取得
    const transaction = await request.env.DB.prepare(`
      SELECT rt.*, r.item_name, r.deposit_amount, r.dojo_id
      FROM rental_transactions rt
      JOIN rentals r ON rt.rental_id = r.id
      WHERE rt.id = ? AND rt.status = 'active'
    `).bind(transactionId).first();

    if (!transaction) {
      return new Response(JSON.stringify({
        error: 'Transaction not found',
        message: 'アクティブなレンタル取引が見つかりません'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // 遅延チェック
    const returnDate = new Date();
    const dueDate = new Date(transaction.return_due_date);
    const isLate = returnDate > dueDate;
    const lateDays = isLate ? Math.ceil((returnDate - dueDate) / (1000 * 60 * 60 * 24)) : 0;

    // 追加料金計算
    const totalLateFee = late_fee || (isLate ? lateDays * 100 : 0); // 1日100円の遅延料
    const totalDamageFee = damage_fee;
    const additionalFees = totalLateFee + totalDamageFee;

    // デポジット返却額計算
    const depositReturn = Math.max(0, transaction.deposit_paid - additionalFees);

    // 取引更新
    await request.env.DB.prepare(`
      UPDATE rental_transactions 
      SET 
        status = 'returned',
        actual_return_date = ?,
        condition_on_return = ?,
        late_fee = ?,
        damage_fee = ?,
        notes = ?,
        updated_at = ?
      WHERE id = ?
    `).bind(
      returnDate.toISOString(),
      condition_on_return,
      totalLateFee,
      totalDamageFee,
      notes,
      new Date().toISOString(),
      transactionId
    ).run();

    // 在庫復元
    await request.env.DB.prepare(`
      UPDATE rentals 
      SET available_quantity = available_quantity + 1,
          updated_at = ?
      WHERE id = ?
    `).bind(new Date().toISOString(), transaction.rental_id).run();

    // 追加料金がある場合は支払い記録作成
    if (additionalFees > 0) {
      await request.env.DB.prepare(`
        INSERT INTO payments (
          payment_type, amount, tax_amount, total_amount, 
          dojo_id, user_id, status, payment_method,
          description, payment_date, paid_at, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `).bind(
        'rental_fee',
        additionalFees,
        0,
        additionalFees,
        transaction.dojo_id,
        transaction.user_id,
        'completed',
        'cash',
        `追加料金: ${transaction.item_name} (遅延: ¥${totalLateFee}, 損傷: ¥${totalDamageFee})`,
        new Date().toISOString(),
        new Date().toISOString(),
        new Date().toISOString()
      ).run();
    }

    return new Response(JSON.stringify({
      message: 'Item returned successfully',
      late_days: lateDays,
      late_fee: totalLateFee,
      damage_fee: totalDamageFee,
      deposit_return: depositReturn,
      additional_fees: additionalFees
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Return rental error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to return rental',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// アクティブなレンタル一覧
router.get('/api/dojo-mode/:dojoId/rentals/active', async (request) => {
  try {
    const { dojoId } = request.params;

    const activeRentals = await request.env.DB.prepare(`
      SELECT 
        rt.*,
        r.item_name,
        r.item_type,
        u.name as customer_name,
        u.phone as customer_phone,
        CASE 
          WHEN DATE(rt.return_due_date) < DATE('now') THEN 'overdue'
          WHEN DATE(rt.return_due_date) = DATE('now') THEN 'due_today'
          ELSE 'active'
        END as urgency_status
      FROM rental_transactions rt
      JOIN rentals r ON rt.rental_id = r.id
      JOIN users u ON rt.user_id = u.id
      WHERE r.dojo_id = ? AND rt.status = 'active'
      ORDER BY 
        CASE 
          WHEN DATE(rt.return_due_date) < DATE('now') THEN 1
          WHEN DATE(rt.return_due_date) = DATE('now') THEN 2
          ELSE 3
        END,
        rt.return_due_date
    `).bind(dojoId).all();

    return new Response(JSON.stringify({
      active_rentals: activeRentals.results
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Get active rentals error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to get active rentals',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// レンタル履歴
router.get('/api/dojo-mode/:dojoId/rentals/history', async (request) => {
  try {
    const { dojoId } = request.params;
    const url = new URL(request.url);
    const limit = parseInt(url.searchParams.get('limit')) || 50;
    const offset = parseInt(url.searchParams.get('offset')) || 0;
    const userId = url.searchParams.get('user_id');

    let query = `
      SELECT 
        rt.*,
        r.item_name,
        r.item_type,
        u.name as customer_name
      FROM rental_transactions rt
      JOIN rentals r ON rt.rental_id = r.id
      JOIN users u ON rt.user_id = u.id
      WHERE r.dojo_id = ?
    `;

    const params = [dojoId];

    if (userId) {
      query += ' AND rt.user_id = ?';
      params.push(userId);
    }

    query += ' ORDER BY rt.created_at DESC LIMIT ? OFFSET ?';
    params.push(limit, offset);

    const history = await request.env.DB.prepare(query).bind(...params).all();

    return new Response(JSON.stringify({
      rental_history: history.results,
      pagination: {
        limit,
        offset,
        has_more: history.results.length === limit
      }
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Get rental history error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to get rental history',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

export { router as rentalRoutes };
