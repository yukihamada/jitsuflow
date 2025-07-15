/**
 * ユーザー向けレンタルAPI
 * レンタル申請、履歴表示
 */

import { Router } from 'itty-router';
import { corsHeaders } from '../middleware/cors';

const router = Router();

// レンタル可能アイテム一覧
router.get('/api/rentals/available', async (request) => {
  try {
    const url = new URL(request.url);
    const category = url.searchParams.get('category');

    let query = `
      SELECT 
        ri.*,
        COUNT(rt.id) as active_rentals
      FROM rental_items ri
      LEFT JOIN rental_transactions rt ON ri.id = rt.rental_item_id 
        AND rt.status = 'active'
      WHERE ri.is_active = 1
    `;

    const params = [];

    if (category) {
      query += ' AND ri.category = ?';
      params.push(category);
    }

    query += ' GROUP BY ri.id ORDER BY ri.name';

    const result = await request.env.DB.prepare(query).bind(...params).all();

    // 利用可能状態を計算
    const items = result.results.map(item => ({
      ...item,
      is_available: item.active_rentals === 0
    }));

    return new Response(JSON.stringify({
      items: items
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Get available rentals error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to get rentals',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// ユーザーのレンタル履歴
router.get('/api/rentals/user/:userId', async (request) => {
  try {
    const { userId } = request.params;

    // 権限確認
    if (request.user.userId !== parseInt(userId) && request.user.role !== 'admin') {
      return new Response(JSON.stringify({
        error: 'Unauthorized'
      }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const rentals = await request.env.DB.prepare(`
      SELECT 
        rt.*,
        ri.name as item_name,
        ri.category,
        ri.size,
        ri.daily_rate,
        ri.deposit_amount,
        u.name as user_name
      FROM rental_transactions rt
      JOIN rental_items ri ON rt.rental_item_id = ri.id
      JOIN users u ON rt.user_id = u.id
      WHERE rt.user_id = ?
      ORDER BY rt.start_date DESC
    `).bind(userId).all();

    return new Response(JSON.stringify({
      rentals: rentals.results
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Get user rentals error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to get rentals',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// レンタル申請
router.post('/api/rentals/request', async (request) => {
  try {
    const { rental_item_id, start_date, end_date } = await request.json();
    const userId = request.user.userId;

    // アイテムの利用可能性確認
    const activeRental = await request.env.DB.prepare(`
      SELECT id FROM rental_transactions
      WHERE rental_item_id = ? AND status = 'active'
      AND ((start_date <= ? AND end_date >= ?)
        OR (start_date <= ? AND end_date >= ?))
    `).bind(
      rental_item_id,
      start_date, start_date,
      end_date, end_date
    ).first();

    if (activeRental) {
      return new Response(JSON.stringify({
        error: 'Item not available for selected dates'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // レンタルアイテム情報取得
    const item = await request.env.DB.prepare(
      'SELECT * FROM rental_items WHERE id = ?'
    ).bind(rental_item_id).first();

    if (!item) {
      return new Response(JSON.stringify({
        error: 'Rental item not found'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // レンタル期間計算
    const startDate = new Date(start_date);
    const endDate = new Date(end_date);
    const days = Math.ceil((endDate - startDate) / (1000 * 60 * 60 * 24));
    const totalAmount = item.deposit_amount + (item.daily_rate * days);

    // レンタル申請作成
    const result = await request.env.DB.prepare(`
      INSERT INTO rental_transactions (
        user_id, rental_item_id, start_date, end_date,
        total_amount, deposit_amount, status, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      userId,
      rental_item_id,
      start_date,
      end_date,
      totalAmount,
      item.deposit_amount,
      'pending',
      new Date().toISOString()
    ).run();

    return new Response(JSON.stringify({
      rental_id: result.meta.last_row_id,
      message: 'Rental request submitted'
    }), {
      status: 201,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Request rental error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to request rental',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// レンタル返却申請
router.post('/api/rentals/:rentalId/return', async (request) => {
  try {
    const { rentalId } = request.params;
    const userId = request.user.userId;

    // レンタル情報取得
    const rental = await request.env.DB.prepare(`
      SELECT * FROM rental_transactions
      WHERE id = ? AND user_id = ? AND status = 'active'
    `).bind(rentalId, userId).first();

    if (!rental) {
      return new Response(JSON.stringify({
        error: 'Active rental not found'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // ステータス更新
    await request.env.DB.prepare(`
      UPDATE rental_transactions
      SET status = 'pending_return', return_date = ?
      WHERE id = ?
    `).bind(new Date().toISOString(), rentalId).run();

    return new Response(JSON.stringify({
      message: 'Return request submitted'
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Return rental error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to process return',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// レンタル延長申請
router.post('/api/rentals/:rentalId/extend', async (request) => {
  try {
    const { rentalId } = request.params;
    const { new_end_date } = await request.json();
    const userId = request.user.userId;

    // レンタル情報取得
    const rental = await request.env.DB.prepare(`
      SELECT rt.*, ri.daily_rate 
      FROM rental_transactions rt
      JOIN rental_items ri ON rt.rental_item_id = ri.id
      WHERE rt.id = ? AND rt.user_id = ? AND rt.status = 'active'
    `).bind(rentalId, userId).first();

    if (!rental) {
      return new Response(JSON.stringify({
        error: 'Active rental not found'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // 延長期間計算
    const currentEndDate = new Date(rental.end_date);
    const newEndDate = new Date(new_end_date);
    const additionalDays = Math.ceil((newEndDate - currentEndDate) / (1000 * 60 * 60 * 24));

    if (additionalDays <= 0) {
      return new Response(JSON.stringify({
        error: 'Invalid extension date'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const additionalAmount = rental.daily_rate * additionalDays;

    // レンタル情報更新
    await request.env.DB.prepare(`
      UPDATE rental_transactions
      SET end_date = ?, total_amount = total_amount + ?
      WHERE id = ?
    `).bind(new_end_date, additionalAmount, rentalId).run();

    return new Response(JSON.stringify({
      message: 'Rental extended successfully',
      additional_amount: additionalAmount
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Extend rental error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to extend rental',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

export { router as userRentalRoutes };
