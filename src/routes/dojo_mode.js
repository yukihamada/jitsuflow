/**
 * Dojo Mode routes for JitsuFlow API
 * 道場モード専用API - POS・レンタル・録画・経営分析
 */

import { Router } from 'itty-router';
import { corsHeaders } from '../middleware/cors';
import { requireAdmin } from '../middleware/auth';
import {
  createPOSPaymentIntent,
  confirmPOSPayment,
  createRefund,
  getOrCreateCustomer,
  generateReceipt
} from '../utils/stripe_helpers';

const router = Router();

// 道場モードデータ取得
router.get('/api/dojo-mode/:dojoId', async (request) => {
  try {
    const { dojoId } = request.params;

    // 道場設定取得
    const settings = await request.env.DB.prepare(`
      SELECT * FROM dojo_mode_settings WHERE dojo_id = ?
    `).bind(dojoId).first();

    // 本日の売上取得
    const todaySales = await request.env.DB.prepare(`
      SELECT 
        st.*,
        u.name as customer_name
      FROM sales_transactions st
      LEFT JOIN users u ON st.user_id = u.id
      WHERE st.dojo_id = ? 
        AND DATE(st.created_at) = DATE('now')
        AND st.status = 'completed'
      ORDER BY st.created_at DESC
    `).bind(dojoId).all();

    // レンタル商品取得
    const rentals = await request.env.DB.prepare(`
      SELECT * FROM rentals 
      WHERE dojo_id = ? AND status = 'available'
      ORDER BY item_type, item_name
    `).bind(dojoId).all();

    // 物販商品取得
    const products = await request.env.DB.prepare(`
      SELECT * FROM products 
      WHERE dojo_id = ? AND status = 'active' AND current_stock > 0
      ORDER BY category, name
    `).bind(dojoId).all();

    // 在庫アラート商品
    const lowStockProducts = await request.env.DB.prepare(`
      SELECT * FROM products 
      WHERE dojo_id = ? AND current_stock <= min_stock_level
    `).bind(dojoId).all();

    return new Response(JSON.stringify({
      settings: settings || {
        pos_enabled: true,
        rental_enabled: true,
        sparring_recording_enabled: true,
        default_tax_rate: 10.0,
        default_member_discount: 10.0,
      },
      today_sales: todaySales.results,
      rentals: rentals.results,
      products: products.results,
      low_stock_alerts: lowStockProducts.results,
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Get dojo mode data error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to get dojo mode data',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// POS決済Intent作成（Stripe）
router.post('/api/dojo-mode/:dojoId/payment-intent', async (request) => {
  try {
    const { dojoId } = request.params;
    const { items, customer_info, discount_amount = 0 } = await request.json();

    const stripe = new Stripe(request.env.STRIPE_SECRET_KEY);

    // 商品詳細取得と金額計算
    let subtotal = 0;
    const itemDetails = [];

    for (const item of items) {
      let itemDetail;
      if (item.type === 'product') {
        itemDetail = await request.env.DB.prepare(
          'SELECT * FROM products WHERE id = ? AND dojo_id = ?'
        ).bind(item.id, dojoId).first();

        if (!itemDetail || itemDetail.current_stock < item.quantity) {
          return new Response(JSON.stringify({
            error: 'Insufficient stock',
            message: `商品 "${itemDetail?.name || item.id}" の在庫が不足しています`
          }), {
            status: 400,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
          });
        }

        const price = customer_info?.user_id ?
          (itemDetail.member_price || itemDetail.selling_price) :
          itemDetail.selling_price;
        subtotal += price * item.quantity;
        itemDetails.push({
          ...itemDetail,
          quantity: item.quantity,
          unit_price: price,
          total_price: price * item.quantity
        });

      } else if (item.type === 'rental') {
        itemDetail = await request.env.DB.prepare(
          'SELECT * FROM rentals WHERE id = ? AND dojo_id = ?'
        ).bind(item.id, dojoId).first();

        if (!itemDetail || itemDetail.available_quantity < item.quantity) {
          return new Response(JSON.stringify({
            error: 'Rental unavailable',
            message: `レンタル商品 "${itemDetail?.item_name || item.id}" が利用できません`
          }), {
            status: 400,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
          });
        }

        subtotal += itemDetail.rental_price * item.quantity;
        itemDetails.push({
          ...itemDetail,
          quantity: item.quantity,
          unit_price: itemDetail.rental_price,
          total_price: itemDetail.rental_price * item.quantity
        });
      }
    }

    // 税額計算
    const settings = await request.env.DB.prepare(
      'SELECT default_tax_rate FROM dojo_mode_settings WHERE dojo_id = ?'
    ).bind(dojoId).first();

    const taxRate = settings?.default_tax_rate || 10.0;
    const taxAmount = Math.round((subtotal - discount_amount) * taxRate / 100);
    const totalAmount = subtotal - discount_amount + taxAmount;

    // 顧客情報処理
    let customerId = null;
    if (customer_info) {
      const customerResult = await getOrCreateCustomer(stripe, {
        email: customer_info.email,
        name: customer_info.name,
        phone: customer_info.phone,
        userId: customer_info.user_id
      }, request.env.DB);

      if (customerResult.success) {
        customerId = customerResult.customer.id;
      }
    }

    // Payment Intent作成
    const paymentResult = await createPOSPaymentIntent(stripe, {
      amount: totalAmount,
      customerId,
      dojoId,
      items: itemDetails,
      metadata: {
        subtotal: subtotal.toString(),
        tax_amount: taxAmount.toString(),
        discount_amount: discount_amount.toString(),
        staff_id: request.user.userId.toString()
      }
    });

    if (!paymentResult.success) {
      return new Response(JSON.stringify({
        error: 'Payment intent creation failed',
        message: paymentResult.error
      }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    return new Response(JSON.stringify({
      client_secret: paymentResult.clientSecret,
      payment_intent_id: paymentResult.paymentIntent.id,
      amount: totalAmount,
      items: itemDetails.length,
      subtotal,
      tax_amount: taxAmount,
      discount_amount,
      total_amount: totalAmount
    }), {
      status: 201,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Create payment intent error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to create payment intent',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// POS決済確認（Stripe）
router.post('/api/dojo-mode/:dojoId/confirm-payment', async (request) => {
  try {
    const { dojoId } = request.params;
    const { payment_intent_id, items } = await request.json();

    const stripe = new Stripe(request.env.STRIPE_SECRET_KEY);

    // Payment Intent取得してメタデータから詳細を復元
    const paymentIntent = await stripe.paymentIntents.retrieve(payment_intent_id);

    if (paymentIntent.status !== 'succeeded') {
      return new Response(JSON.stringify({
        error: 'Payment not completed',
        message: '決済が完了していません'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const metadata = paymentIntent.metadata;
    const subtotal = parseInt(metadata.subtotal);
    const taxAmount = parseInt(metadata.tax_amount);
    const discountAmount = parseInt(metadata.discount_amount);
    const totalAmount = paymentIntent.amount;

    // 在庫更新・レンタル記録作成
    for (const item of items) {
      if (item.type === 'product') {
        await request.env.DB.prepare(
          'UPDATE products SET current_stock = current_stock - ? WHERE id = ?'
        ).bind(item.quantity, item.id).run();

      } else if (item.type === 'rental') {
        await request.env.DB.prepare(
          'UPDATE rentals SET available_quantity = available_quantity - ? WHERE id = ?'
        ).bind(item.quantity, item.id).run();

        // レンタル履歴作成
        await request.env.DB.prepare(`
          INSERT INTO rental_transactions (
            rental_id, user_id, rental_date, return_due_date, 
            rental_fee, deposit_paid, total_paid, status, created_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        `).bind(
          item.id,
          paymentIntent.customer || null,
          new Date().toISOString(),
          new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
          item.unit_price,
          item.deposit_amount || 0,
          item.total_price,
          'active',
          new Date().toISOString()
        ).run();
      }
    }

    // 決済確認とレシート生成
    const confirmResult = await confirmPOSPayment(stripe, payment_intent_id, request.env.DB, {
      dojoId,
      staffId: request.user.userId,
      items,
      subtotal,
      taxAmount,
      discountAmount,
      totalAmount
    });

    if (!confirmResult.success) {
      return new Response(JSON.stringify({
        error: 'Payment confirmation failed',
        message: confirmResult.error
      }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // 道場名取得してレシート生成
    const dojo = await request.env.DB.prepare(
      'SELECT name FROM dojos WHERE id = ?'
    ).bind(dojoId).first();

    const receipt = generateReceipt({
      transactionId: confirmResult.transactionId,
      dojoName: dojo?.name || '道場',
      items,
      subtotal,
      taxAmount,
      discountAmount,
      totalAmount,
      paymentMethod: 'credit_card',
      timestamp: new Date().toISOString(),
      customerName: paymentIntent.customer ? 'お客様' : 'ゲスト'
    });

    return new Response(JSON.stringify({
      message: 'Payment completed successfully',
      transaction_id: confirmResult.transactionId,
      payment_intent_id,
      receipt,
      total_amount: totalAmount
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Confirm payment error:', error);

    return new Response(JSON.stringify({
      error: 'Payment confirmation failed',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// POS決済処理（現金）
router.post('/api/dojo-mode/:dojoId/payment', async (request) => {
  try {
    const { dojoId } = request.params;
    const { items, payment_method, customer_id, discount_amount = 0 } = await request.json();

    // 商品・レンタル詳細取得して金額計算
    let subtotal = 0;
    const itemDetails = [];

    for (const item of items) {
      let itemDetail;
      if (item.type === 'product') {
        itemDetail = await request.env.DB.prepare(
          'SELECT * FROM products WHERE id = ? AND dojo_id = ?'
        ).bind(item.id, dojoId).first();

        if (!itemDetail || itemDetail.current_stock < item.quantity) {
          return new Response(JSON.stringify({
            error: 'Insufficient stock',
            message: `商品 "${itemDetail?.name || item.id}" の在庫が不足しています`
          }), {
            status: 400,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
          });
        }

        const price = customer_id ? (itemDetail.member_price || itemDetail.selling_price) : itemDetail.selling_price;
        subtotal += price * item.quantity;
        itemDetails.push({
          ...itemDetail,
          quantity: item.quantity,
          unit_price: price,
          total_price: price * item.quantity
        });

      } else if (item.type === 'rental') {
        itemDetail = await request.env.DB.prepare(
          'SELECT * FROM rentals WHERE id = ? AND dojo_id = ?'
        ).bind(item.id, dojoId).first();

        if (!itemDetail || itemDetail.available_quantity < item.quantity) {
          return new Response(JSON.stringify({
            error: 'Rental unavailable',
            message: `レンタル商品 "${itemDetail?.item_name || item.id}" が利用できません`
          }), {
            status: 400,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
          });
        }

        subtotal += itemDetail.rental_price * item.quantity;
        itemDetails.push({
          ...itemDetail,
          quantity: item.quantity,
          unit_price: itemDetail.rental_price,
          total_price: itemDetail.rental_price * item.quantity
        });
      }
    }

    // 税額計算
    const settings = await request.env.DB.prepare(
      'SELECT default_tax_rate FROM dojo_mode_settings WHERE dojo_id = ?'
    ).bind(dojoId).first();

    const taxRate = settings?.default_tax_rate || 10.0;
    const taxAmount = Math.round((subtotal - discount_amount) * taxRate / 100);
    const totalAmount = subtotal - discount_amount + taxAmount;

    // トランザクション開始
    const transactionId = `txn_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    // 売上記録作成
    await request.env.DB.prepare(`
      INSERT INTO sales_transactions (
        transaction_type, dojo_id, user_id, staff_id, subtotal, 
        tax_amount, discount_amount, total_amount, payment_method, 
        items_detail, receipt_number, status, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      'pos_sale',
      dojoId,
      customer_id,
      request.user.userId,
      subtotal,
      taxAmount,
      discount_amount,
      totalAmount,
      payment_method,
      JSON.stringify(itemDetails),
      transactionId,
      'completed',
      new Date().toISOString()
    ).run();

    // 在庫更新・レンタル記録作成
    for (const item of items) {
      if (item.type === 'product') {
        await request.env.DB.prepare(
          'UPDATE products SET current_stock = current_stock - ? WHERE id = ?'
        ).bind(item.quantity, item.id).run();

      } else if (item.type === 'rental') {
        await request.env.DB.prepare(
          'UPDATE rentals SET available_quantity = available_quantity - ? WHERE id = ?'
        ).bind(item.quantity, item.id).run();

        // レンタル履歴作成
        await request.env.DB.prepare(`
          INSERT INTO rental_transactions (
            rental_id, user_id, rental_date, return_due_date, 
            rental_fee, deposit_paid, total_paid, status, created_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        `).bind(
          item.id,
          customer_id || null,
          new Date().toISOString(),
          new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(), // 7日後
          itemDetails.find(detail => detail.id === item.id).unit_price,
          itemDetails.find(detail => detail.id === item.id).deposit_amount || 0,
          itemDetails.find(detail => detail.id === item.id).total_price,
          'active',
          new Date().toISOString()
        ).run();
      }
    }

    // 支払い記録作成
    await request.env.DB.prepare(`
      INSERT INTO payments (
        payment_type, amount, tax_amount, total_amount, dojo_id, 
        user_id, status, payment_method, pos_transaction_id, 
        receipt_data, payment_date, paid_at, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      'purchase',
      subtotal,
      taxAmount,
      totalAmount,
      dojoId,
      customer_id,
      'completed',
      payment_method,
      transactionId,
      JSON.stringify({
        items: itemDetails,
        subtotal,
        tax_amount: taxAmount,
        discount_amount,
        total_amount: totalAmount,
        payment_method
      }),
      new Date().toISOString(),
      new Date().toISOString(),
      new Date().toISOString()
    ).run();

    return new Response(JSON.stringify({
      message: 'Payment processed successfully',
      transaction_id: transactionId,
      receipt_number: transactionId,
      total_amount: totalAmount,
      items: itemDetails.length,
      payment_method
    }), {
      status: 201,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Process payment error:', error);

    return new Response(JSON.stringify({
      error: 'Payment processing failed',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// 本日売上取得
router.get('/api/dojo-mode/:dojoId/sales/today', async (request) => {
  try {
    const { dojoId } = request.params;

    const sales = await request.env.DB.prepare(`
      SELECT 
        st.*,
        u.name as customer_name,
        staff.name as staff_name
      FROM sales_transactions st
      LEFT JOIN users u ON st.user_id = u.id
      LEFT JOIN users staff ON st.staff_id = staff.id
      WHERE st.dojo_id = ? 
        AND DATE(st.created_at) = DATE('now')
      ORDER BY st.created_at DESC
    `).bind(dojoId).all();

    // 今日の合計統計
    const summary = await request.env.DB.prepare(`
      SELECT 
        COUNT(*) as transaction_count,
        SUM(total_amount) as total_revenue,
        SUM(CASE WHEN transaction_type = 'product_sale' THEN total_amount ELSE 0 END) as product_revenue,
        SUM(CASE WHEN transaction_type = 'rental' THEN total_amount ELSE 0 END) as rental_revenue,
        AVG(total_amount) as average_sale
      FROM sales_transactions 
      WHERE dojo_id = ? 
        AND DATE(created_at) = DATE('now')
        AND status = 'completed'
    `).bind(dojoId).first();

    return new Response(JSON.stringify({
      sales: sales.results,
      summary: summary || {
        transaction_count: 0,
        total_revenue: 0,
        product_revenue: 0,
        rental_revenue: 0,
        average_sale: 0
      }
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Get today sales error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to get today sales',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// スパーリング録画開始
router.post('/api/dojo-mode/:dojoId/sparring/start', async (request) => {
  try {
    const { dojoId } = request.params;
    const { participant_1_id, participant_2_id, rule_set, weight_class } = await request.json();

    // 参加者の存在確認
    const participant1 = await request.env.DB.prepare(
      'SELECT id, name FROM users WHERE id = ?'
    ).bind(participant_1_id).first();

    const participant2 = await request.env.DB.prepare(
      'SELECT id, name FROM users WHERE id = ?'
    ).bind(participant_2_id).first();

    if (!participant1 || !participant2) {
      return new Response(JSON.stringify({
        error: 'Participant not found',
        message: '参加者が見つかりません'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // 録画記録作成
    const result = await request.env.DB.prepare(`
      INSERT INTO sparring_videos (
        dojo_id, recorded_by, recording_date, participant_1_id, 
        participant_2_id, rule_set, weight_class, status, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      dojoId,
      request.user.userId,
      new Date().toISOString(),
      participant_1_id,
      participant_2_id,
      rule_set,
      weight_class,
      'recording',
      new Date().toISOString()
    ).run();

    return new Response(JSON.stringify({
      message: 'Recording started successfully',
      recording_id: result.meta.last_row_id,
      participants: {
        participant_1: participant1,
        participant_2: participant2
      },
      rule_set,
      started_at: new Date().toISOString()
    }), {
      status: 201,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Start recording error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to start recording',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// スパーリング録画停止
router.patch('/api/sparring-videos/:recordingId/stop', async (request) => {
  try {
    const { recordingId } = request.params;
    const { winner_id, finish_type, duration, notes } = await request.json();

    // 録画記録更新
    const result = await request.env.DB.prepare(`
      UPDATE sparring_videos 
      SET 
        status = 'available',
        winner_id = ?,
        finish_type = ?,
        duration = ?,
        notes = ?,
        updated_at = ?
      WHERE id = ? AND status = 'recording'
    `).bind(
      winner_id,
      finish_type,
      duration,
      notes,
      new Date().toISOString(),
      recordingId
    ).run();

    if (result.changes === 0) {
      return new Response(JSON.stringify({
        error: 'Recording not found',
        message: '録画が見つからないか、既に停止されています'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    return new Response(JSON.stringify({
      message: 'Recording stopped successfully',
      recording_id: recordingId,
      finish_type,
      duration
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Stop recording error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to stop recording',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// 録画一覧取得
router.get('/api/dojo-mode/:dojoId/sparring/videos', async (request) => {
  try {
    const { dojoId } = request.params;
    const url = new URL(request.url);
    const limit = parseInt(url.searchParams.get('limit')) || 20;
    const offset = parseInt(url.searchParams.get('offset')) || 0;

    const videos = await request.env.DB.prepare(`
      SELECT 
        sv.*,
        p1.name as participant_1_name,
        p2.name as participant_2_name,
        winner.name as winner_name,
        recorder.name as recorded_by_name
      FROM sparring_videos sv
      JOIN users p1 ON sv.participant_1_id = p1.id
      JOIN users p2 ON sv.participant_2_id = p2.id
      LEFT JOIN users winner ON sv.winner_id = winner.id
      LEFT JOIN users recorder ON sv.recorded_by = recorder.id
      WHERE sv.dojo_id = ? AND sv.status IN ('available', 'processing')
      ORDER BY sv.recording_date DESC
      LIMIT ? OFFSET ?
    `).bind(dojoId, limit, offset).all();

    return new Response(JSON.stringify({
      videos: videos.results,
      pagination: {
        limit,
        offset,
        has_more: videos.results.length === limit
      }
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Get sparring videos error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to get videos',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// 返金処理
router.post('/api/dojo-mode/:dojoId/refund', async (request) => {
  try {
    // 管理者権限チェック
    const adminCheck = requireAdmin(request);
    if (adminCheck) return adminCheck;

    const { payment_intent_id, amount, reason = 'requested_by_customer' } = await request.json();

    if (!payment_intent_id) {
      return new Response(JSON.stringify({
        error: 'Missing payment intent ID',
        message: 'Payment Intent IDが必要です'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const stripe = new Stripe(request.env.STRIPE_SECRET_KEY);

    // 返金処理
    const refundResult = await createRefund(stripe, payment_intent_id, amount, reason, request.env.DB);

    if (!refundResult.success) {
      return new Response(JSON.stringify({
        error: 'Refund failed',
        message: refundResult.error
      }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    return new Response(JSON.stringify({
      message: 'Refund processed successfully',
      refund_id: refundResult.refundId,
      amount: refundResult.refund.amount,
      status: refundResult.refund.status
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Process refund error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to process refund',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

export { router as dojoModeRoutes };
