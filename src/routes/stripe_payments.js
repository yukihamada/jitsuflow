/**
 * Payment routes for JitsuFlow API
 * Stripe integration for orders, subscriptions, and POS payments
 */

import { Router } from 'itty-router';

const router = Router();

// CORS headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Requested-With',
  'Access-Control-Max-Age': '86400'
};

// Stripe API helper
async function stripeRequest(endpoint, method = 'POST', data = {}, stripeSecretKey) {
  const url = `https://api.stripe.com/v1/${endpoint}`;

  const formData = new URLSearchParams();
  Object.keys(data).forEach(key => {
    if (data[key] !== undefined && data[key] !== null) {
      if (typeof data[key] === 'object' && !Array.isArray(data[key])) {
        // Handle nested objects
        Object.keys(data[key]).forEach(subKey => {
          formData.append(`${key}[${subKey}]`, data[key][subKey]);
        });
      } else {
        formData.append(key, data[key].toString());
      }
    }
  });

  const response = await fetch(url, {
    method,
    headers: {
      'Authorization': `Bearer ${stripeSecretKey}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: method !== 'GET' ? formData : undefined,
  });

  const result = await response.json();

  if (!response.ok) {
    throw new Error(result.error?.message || 'Stripe API error');
  }

  return result;
}

// Generate order number
function generateOrderNumber() {
  const timestamp = Date.now().toString(36);
  const random = Math.random().toString(36).substr(2, 5);
  return `JF-${timestamp}-${random}`.toUpperCase();
}

// Create order from cart
router.post('/api/orders/create', async (request) => {
  try {
    const userId = request.user.userId;
    const { shipping_address, billing_address } = await request.json();

    // Get cart items
    const cartResult = await request.env.DB.prepare(`
      SELECT 
        sc.*,
        p.name as product_name,
        p.price,
        p.stock_quantity
      FROM shopping_carts sc
      JOIN products p ON sc.product_id = p.id
      WHERE sc.user_id = ?
    `).bind(userId).all();

    if (cartResult.results.length === 0) {
      return new Response(JSON.stringify({
        error: 'Cart is empty'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Calculate totals
    let subtotal = 0;
    for (const item of cartResult.results) {
      subtotal += item.price * item.quantity;
    }

    const taxRate = 0.10; // 10% tax
    const taxAmount = Math.round(subtotal * taxRate);
    const totalAmount = subtotal + taxAmount;

    // Create order
    const orderNumber = generateOrderNumber();
    const orderResult = await request.env.DB.prepare(`
      INSERT INTO orders (
        user_id, order_number, status, subtotal, tax_amount, 
        total_amount, shipping_address, billing_address, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      userId,
      orderNumber,
      'pending',
      subtotal,
      taxAmount,
      totalAmount,
      JSON.stringify(shipping_address),
      JSON.stringify(billing_address || shipping_address),
      new Date().toISOString(),
      new Date().toISOString()
    ).run();

    const orderId = orderResult.meta.last_row_id;

    // Create order items
    for (const item of cartResult.results) {
      await request.env.DB.prepare(`
        INSERT INTO order_items (order_id, product_id, quantity, unit_price, total_price)
        VALUES (?, ?, ?, ?, ?)
      `).bind(
        orderId,
        item.product_id,
        item.quantity,
        item.price,
        item.price * item.quantity
      ).run();

      // Update stock
      await request.env.DB.prepare(
        'UPDATE products SET stock_quantity = stock_quantity - ? WHERE id = ?'
      ).bind(item.quantity, item.product_id).run();
    }

    // Clear cart
    await request.env.DB.prepare(
      'DELETE FROM shopping_carts WHERE user_id = ?'
    ).bind(userId).run();

    return new Response(JSON.stringify({
      order: {
        id: orderId,
        order_number: orderNumber,
        status: 'pending',
        subtotal,
        tax_amount: taxAmount,
        total_amount: totalAmount,
        items_count: cartResult.results.length
      }
    }), {
      status: 201,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Create order error:', error);
    return new Response(JSON.stringify({
      error: 'Failed to create order',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Create payment intent for order
router.post('/api/payments/create-intent', async (request) => {
  try {
    const { order_id } = await request.json();
    const userId = request.user.userId;

    // Get order details
    const order = await request.env.DB.prepare(
      'SELECT * FROM orders WHERE id = ? AND user_id = ?'
    ).bind(order_id, userId).first();

    if (!order) {
      return new Response(JSON.stringify({
        error: 'Order not found'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    if (order.payment_status === 'paid') {
      return new Response(JSON.stringify({
        error: 'Order already paid'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Get user info
    const user = await request.env.DB.prepare(
      'SELECT * FROM users WHERE id = ?'
    ).bind(userId).first();

    // Create or get Stripe customer
    let customerId = user.stripe_customer_id;
    if (!customerId) {
      const customer = await stripeRequest('customers', 'POST', {
        email: user.email,
        name: user.name,
        metadata: {
          user_id: userId.toString()
        }
      }, request.env.STRIPE_SECRET_KEY);

      customerId = customer.id;

      // Save customer ID
      await request.env.DB.prepare(
        'UPDATE users SET stripe_customer_id = ? WHERE id = ?'
      ).bind(customerId, userId).run();
    }

    // Create payment intent
    const paymentIntent = await stripeRequest('payment_intents', 'POST', {
      amount: order.total_amount,
      currency: 'jpy',
      customer: customerId,
      metadata: {
        order_id: order_id.toString(),
        order_number: order.order_number
      },
      description: `Order ${order.order_number}`
    }, request.env.STRIPE_SECRET_KEY);

    // Create payment record
    await request.env.DB.prepare(`
      INSERT INTO payments (
        user_id, order_id, payment_type, amount, currency,
        payment_method, stripe_payment_intent_id, status, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      userId,
      order_id,
      'order',
      order.total_amount,
      'JPY',
      'stripe',
      paymentIntent.id,
      'pending',
      new Date().toISOString()
    ).run();

    return new Response(JSON.stringify({
      client_secret: paymentIntent.client_secret,
      payment_intent_id: paymentIntent.id,
      amount: order.total_amount
    }), {
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

// Confirm payment (webhook handler)
router.post('/api/payments/webhook', async (request) => {
  try {
    const body = await request.text();

    // Note: For production, implement proper webhook signature verification
    const event = JSON.parse(body);

    console.log('Stripe webhook event:', event.type);

    switch (event.type) {
    case 'payment_intent.succeeded': {
      const paymentIntent = event.data.object;
      const orderId = paymentIntent.metadata.order_id;

      if (orderId) {
        // Update payment status
        await request.env.DB.prepare(`
            UPDATE payments 
            SET status = 'completed', paid_at = ?, updated_at = ?
            WHERE stripe_payment_intent_id = ?
          `).bind(
          new Date().toISOString(),
          new Date().toISOString(),
          paymentIntent.id
        ).run();

        // Update order status
        await request.env.DB.prepare(`
            UPDATE orders 
            SET payment_status = 'paid', status = 'processing', updated_at = ?
            WHERE id = ?
          `).bind(
          new Date().toISOString(),
          orderId
        ).run();

        // TODO: Send confirmation email
      }
      break;
    }

    case 'payment_intent.payment_failed': {
      const paymentIntent = event.data.object;

      await request.env.DB.prepare(`
          UPDATE payments 
          SET status = 'failed', updated_at = ?
          WHERE stripe_payment_intent_id = ?
        `).bind(
        new Date().toISOString(),
        paymentIntent.id
      ).run();
      break;
    }

    case 'customer.subscription.created':
    case 'customer.subscription.updated': {
      const subscription = event.data.object;
      const userId = subscription.metadata.user_id;

      if (userId) {
        await request.env.DB.prepare(`
            INSERT INTO subscriptions (
              user_id, stripe_subscription_id, stripe_customer_id,
              plan_id, plan_name, status, current_period_start,
              current_period_end, created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(stripe_subscription_id) DO UPDATE SET
              status = excluded.status,
              current_period_start = excluded.current_period_start,
              current_period_end = excluded.current_period_end,
              updated_at = excluded.updated_at
          `).bind(
          userId,
          subscription.id,
          subscription.customer,
          subscription.items.data[0].price.id,
          subscription.items.data[0].price.nickname || 'Premium',
          subscription.status,
          new Date(subscription.current_period_start * 1000).toISOString(),
          new Date(subscription.current_period_end * 1000).toISOString(),
          new Date().toISOString(),
          new Date().toISOString()
        ).run();

        // Update user role
        if (subscription.status === 'active' || subscription.status === 'trialing') {
          await request.env.DB.prepare(
            'UPDATE users SET role = ? WHERE id = ?'
          ).bind('premium', userId).run();
        }
      }
      break;
    }

    case 'customer.subscription.deleted': {
      const subscription = event.data.object;

      await request.env.DB.prepare(`
          UPDATE subscriptions 
          SET status = 'cancelled', cancelled_at = ?, updated_at = ?
          WHERE stripe_subscription_id = ?
        `).bind(
        new Date().toISOString(),
        new Date().toISOString(),
        subscription.id
      ).run();

      // Update user role
      const userId = subscription.metadata.user_id;
      if (userId) {
        await request.env.DB.prepare(
          'UPDATE users SET role = ? WHERE id = ?'
        ).bind('user', userId).run();
      }
      break;
    }
    }

    return new Response(JSON.stringify({ received: true }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Webhook error:', error);
    return new Response(JSON.stringify({
      error: 'Webhook processing failed',
      message: error.message
    }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Create subscription
router.post('/api/subscriptions/create', async (request) => {
  try {
    const userId = request.user.userId;
    const { price_id, payment_method_id } = await request.json();

    // Get user
    const user = await request.env.DB.prepare(
      'SELECT * FROM users WHERE id = ?'
    ).bind(userId).first();

    // Create or get customer
    let customerId = user.stripe_customer_id;
    if (!customerId) {
      const customer = await stripeRequest('customers', 'POST', {
        email: user.email,
        name: user.name,
        payment_method: payment_method_id,
        invoice_settings: {
          default_payment_method: payment_method_id
        },
        metadata: {
          user_id: userId.toString()
        }
      }, request.env.STRIPE_SECRET_KEY);

      customerId = customer.id;

      await request.env.DB.prepare(
        'UPDATE users SET stripe_customer_id = ? WHERE id = ?'
      ).bind(customerId, userId).run();
    } else {
      // Attach payment method to customer
      await stripeRequest(`payment_methods/${payment_method_id}/attach`, 'POST', {
        customer: customerId
      }, request.env.STRIPE_SECRET_KEY);

      // Set as default
      await stripeRequest(`customers/${customerId}`, 'POST', {
        invoice_settings: {
          default_payment_method: payment_method_id
        }
      }, request.env.STRIPE_SECRET_KEY);
    }

    // Create subscription with trial
    const subscription = await stripeRequest('subscriptions', 'POST', {
      customer: customerId,
      items: [{
        price: price_id
      }],
      trial_period_days: 30, // 30-day free trial
      metadata: {
        user_id: userId.toString()
      }
    }, request.env.STRIPE_SECRET_KEY);

    return new Response(JSON.stringify({
      subscription: {
        id: subscription.id,
        status: subscription.status,
        trial_end: new Date(subscription.trial_end * 1000).toISOString(),
        current_period_end: new Date(subscription.current_period_end * 1000).toISOString()
      }
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Create subscription error:', error);
    return new Response(JSON.stringify({
      error: 'Failed to create subscription',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Cancel subscription
router.post('/api/subscriptions/cancel', async (request) => {
  try {
    const userId = request.user.userId;

    // Get active subscription
    const subscription = await request.env.DB.prepare(
      'SELECT * FROM subscriptions WHERE user_id = ? AND status = ?'
    ).bind(userId, 'active').first();

    if (!subscription) {
      return new Response(JSON.stringify({
        error: 'No active subscription found'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Cancel at period end
    await stripeRequest(
      `subscriptions/${subscription.stripe_subscription_id}`,
      'POST',
      {
        cancel_at_period_end: true
      },
      request.env.STRIPE_SECRET_KEY
    );

    // Update database
    await request.env.DB.prepare(`
      UPDATE subscriptions 
      SET cancel_at_period_end = 1, updated_at = ?
      WHERE id = ?
    `).bind(
      new Date().toISOString(),
      subscription.id
    ).run();

    return new Response(JSON.stringify({
      message: 'Subscription will be cancelled at period end',
      cancel_at: subscription.current_period_end
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Cancel subscription error:', error);
    return new Response(JSON.stringify({
      error: 'Failed to cancel subscription',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Get user orders
router.get('/api/orders', async (request) => {
  try {
    const userId = request.user.userId;
    const url = new URL(request.url);
    const status = url.searchParams.get('status');
    const limit = parseInt(url.searchParams.get('limit')) || 20;
    const offset = parseInt(url.searchParams.get('offset')) || 0;

    let query = `
      SELECT o.*, 
        (SELECT COUNT(*) FROM order_items WHERE order_id = o.id) as items_count
      FROM orders o
      WHERE o.user_id = ?
    `;

    const params = [userId];

    if (status) {
      query += ' AND o.status = ?';
      params.push(status);
    }

    query += ' ORDER BY o.created_at DESC LIMIT ? OFFSET ?';
    params.push(limit, offset);

    const result = await request.env.DB.prepare(query).bind(...params).all();

    return new Response(JSON.stringify({
      orders: result.results || [],
      pagination: {
        limit,
        offset,
        hasMore: result.results.length === limit
      }
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Get orders error:', error);
    return new Response(JSON.stringify({
      error: 'Failed to get orders',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Get order details
router.get('/api/orders/:id', async (request) => {
  try {
    const { id } = request.params;
    const userId = request.user.userId;

    // Get order
    const order = await request.env.DB.prepare(
      'SELECT * FROM orders WHERE id = ? AND user_id = ?'
    ).bind(id, userId).first();

    if (!order) {
      return new Response(JSON.stringify({
        error: 'Order not found'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Get order items
    const items = await request.env.DB.prepare(`
      SELECT oi.*, p.name, p.description, p.image_url
      FROM order_items oi
      JOIN products p ON oi.product_id = p.id
      WHERE oi.order_id = ?
    `).bind(id).all();

    // Get payment info
    const payment = await request.env.DB.prepare(
      'SELECT * FROM payments WHERE order_id = ?'
    ).bind(id).first();

    return new Response(JSON.stringify({
      order: {
        ...order,
        items: items.results,
        payment: payment
      }
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Get order details error:', error);
    return new Response(JSON.stringify({
      error: 'Failed to get order details',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Process refund
router.post('/api/payments/:id/refund', async (request) => {
  try {
    const { id } = request.params;
    const { amount, reason } = await request.json();
    const userId = request.user.userId;

    // Get payment
    const payment = await request.env.DB.prepare(
      'SELECT p.*, o.user_id FROM payments p JOIN orders o ON p.order_id = o.id WHERE p.id = ? AND o.user_id = ?'
    ).bind(id, userId).first();

    if (!payment) {
      return new Response(JSON.stringify({
        error: 'Payment not found'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    if (payment.status !== 'completed') {
      return new Response(JSON.stringify({
        error: 'Payment not completed'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Create refund
    const refund = await stripeRequest('refunds', 'POST', {
      payment_intent: payment.stripe_payment_intent_id,
      amount: amount || payment.amount, // Partial or full refund
      reason: reason || 'requested_by_customer'
    }, request.env.STRIPE_SECRET_KEY);

    // Update payment record
    await request.env.DB.prepare(`
      UPDATE payments 
      SET refund_amount = refund_amount + ?, 
          refund_reason = ?,
          status = CASE 
            WHEN refund_amount + ? >= amount THEN 'refunded'
            ELSE 'partial_refund'
          END,
          refunded_at = ?,
          updated_at = ?
      WHERE id = ?
    `).bind(
      refund.amount,
      reason,
      refund.amount,
      new Date().toISOString(),
      new Date().toISOString(),
      id
    ).run();

    // Update order if fully refunded
    if (refund.amount === payment.amount) {
      await request.env.DB.prepare(`
        UPDATE orders 
        SET status = 'refunded', payment_status = 'refunded', updated_at = ?
        WHERE id = ?
      `).bind(
        new Date().toISOString(),
        payment.order_id
      ).run();
    }

    return new Response(JSON.stringify({
      refund: {
        id: refund.id,
        amount: refund.amount,
        status: refund.status,
        reason: refund.reason
      }
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

export { router as paymentRoutes };
