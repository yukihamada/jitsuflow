/**
 * Payment routes for JitsuFlow API
 * 決済API - Stripe統合（月額課金・プロモーション・POS決済）
 */

import { Router } from 'itty-router';
import { corsHeaders } from '../middleware/cors';

const router = Router();

// Create subscription
router.post('/api/payments/create-subscription', async (request) => {
  try {
    const { price_id, payment_method_id } = await request.json();

    if (!price_id || !payment_method_id) {
      return new Response(JSON.stringify({
        error: 'Missing required fields',
        message: 'Price ID and payment method ID are required'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const stripe = new Stripe(request.env.STRIPE_SECRET_KEY);

    // Get user info
    const user = await request.env.DB.prepare(
      'SELECT * FROM users WHERE id = ?'
    ).bind(request.user.userId).first();

    if (!user) {
      return new Response(JSON.stringify({
        error: 'User not found'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Create or get Stripe customer
    let customer;
    if (user.stripe_customer_id) {
      customer = await stripe.customers.retrieve(user.stripe_customer_id);
    } else {
      customer = await stripe.customers.create({
        email: user.email,
        name: user.name,
        metadata: { user_id: user.id }
      });

      // Update user with Stripe customer ID
      await request.env.DB.prepare(
        'UPDATE users SET stripe_customer_id = ? WHERE id = ?'
      ).bind(customer.id, user.id).run();
    }

    // Attach payment method to customer
    await stripe.paymentMethods.attach(payment_method_id, {
      customer: customer.id
    });

    // Create subscription
    const subscription = await stripe.subscriptions.create({
      customer: customer.id,
      items: [{ price: price_id }],
      default_payment_method: payment_method_id,
      expand: ['latest_invoice.payment_intent']
    });

    // Save subscription to database
    await request.env.DB.prepare(
      'INSERT INTO subscriptions (user_id, stripe_subscription_id, status, current_period_start, current_period_end, created_at) VALUES (?, ?, ?, ?, ?, ?)'
    ).bind(
      user.id,
      subscription.id,
      subscription.status,
      new Date(subscription.current_period_start * 1000).toISOString(),
      new Date(subscription.current_period_end * 1000).toISOString(),
      new Date().toISOString()
    ).run();

    return new Response(JSON.stringify({
      message: 'Subscription created successfully',
      subscription: {
        id: subscription.id,
        status: subscription.status,
        current_period_start: subscription.current_period_start,
        current_period_end: subscription.current_period_end
      }
    }), {
      status: 201,
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

// Get subscription status
router.get('/api/payments/subscription', async (request) => {
  try {
    const subscription = await request.env.DB.prepare(
      'SELECT * FROM subscriptions WHERE user_id = ? ORDER BY created_at DESC LIMIT 1'
    ).bind(request.user.userId).first();

    if (!subscription) {
      return new Response(JSON.stringify({
        subscription: null,
        has_active_subscription: false
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    return new Response(JSON.stringify({
      subscription,
      has_active_subscription: subscription.status === 'active'
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Get subscription error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to get subscription',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Cancel subscription
router.post('/api/payments/cancel-subscription', async (request) => {
  try {
    const { immediate = false } = await request.json();

    const subscription = await request.env.DB.prepare(
      'SELECT * FROM subscriptions WHERE user_id = ? AND status = "active"'
    ).bind(request.user.userId).first();

    if (!subscription) {
      return new Response(JSON.stringify({
        error: 'No active subscription found'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const stripe = new Stripe(request.env.STRIPE_SECRET_KEY);

    // Cancel subscription in Stripe
    const canceledSubscription = await stripe.subscriptions.update(subscription.stripe_subscription_id, {
      cancel_at_period_end: !immediate
    });

    if (immediate) {
      await stripe.subscriptions.cancel(subscription.stripe_subscription_id);
    }

    // Update subscription status in database
    const newStatus = immediate ? 'canceled' : 'canceling';
    await request.env.DB.prepare(
      'UPDATE subscriptions SET status = ?, updated_at = ? WHERE id = ?'
    ).bind(newStatus, new Date().toISOString(), subscription.id).run();

    return new Response(JSON.stringify({
      message: immediate ? 'Subscription canceled immediately' : 'Subscription will cancel at period end',
      cancellation_date: immediate ? new Date().toISOString() : new Date(canceledSubscription.current_period_end * 1000).toISOString()
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

// サブスクリプション変更
router.put('/api/payments/subscription/:subscriptionId', async (request) => {
  try {
    const { subscriptionId } = request.params;
    const {
      new_price_id,
      proration_behavior = 'create_prorations',
      apply_discount_code,
      remove_discount = false
    } = await request.json();

    const stripe = new Stripe(request.env.STRIPE_SECRET_KEY);

    // 現在のサブスクリプション取得
    const subscription = await stripe.subscriptions.retrieve(subscriptionId);

    // 更新パラメータ準備
    const updateParams = {
      items: [{
        id: subscription.items.data[0].id,
        price: new_price_id
      }],
      proration_behavior
    };

    // 割引コード適用
    if (apply_discount_code) {
      const promoCodes = await stripe.promotionCodes.list({
        code: apply_discount_code,
        limit: 1
      });
      if (promoCodes.data.length > 0) {
        updateParams.coupon = promoCodes.data[0].coupon.id;
      }
    }

    // 割引削除
    if (remove_discount) {
      updateParams.coupon = '';
    }

    // サブスクリプション更新
    const updatedSubscription = await stripe.subscriptions.update(subscriptionId, updateParams);

    // DB更新
    await request.env.DB.prepare(`
      UPDATE subscriptions 
      SET stripe_price_id = ?, 
          status = ?, 
          current_period_start = ?, 
          current_period_end = ?, 
          updated_at = ?
      WHERE stripe_subscription_id = ?
    `).bind(
      new_price_id,
      updatedSubscription.status,
      new Date(updatedSubscription.current_period_start * 1000).toISOString(),
      new Date(updatedSubscription.current_period_end * 1000).toISOString(),
      new Date().toISOString(),
      subscriptionId
    ).run();

    return new Response(JSON.stringify({
      message: 'Subscription updated successfully',
      subscription_id: subscriptionId,
      new_price_id,
      status: updatedSubscription.status,
      next_billing_date: new Date(updatedSubscription.current_period_end * 1000).toISOString()
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Update subscription error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to update subscription',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// サブスクリプション一時停止
router.post('/api/payments/subscription/:subscriptionId/pause', async (request) => {
  try {
    const { subscriptionId } = request.params;
    const { pause_collection = { behavior: 'void' } } = await request.json();

    const stripe = new Stripe(request.env.STRIPE_SECRET_KEY);

    // サブスクリプション一時停止
    await stripe.subscriptions.update(subscriptionId, {
      pause_collection
    });

    // DB更新
    await request.env.DB.prepare(`
      UPDATE subscriptions 
      SET status = 'paused', updated_at = ?
      WHERE stripe_subscription_id = ?
    `).bind(new Date().toISOString(), subscriptionId).run();

    return new Response(JSON.stringify({
      message: 'Subscription paused successfully',
      subscription_id: subscriptionId,
      status: 'paused'
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Pause subscription error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to pause subscription',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// サブスクリプション再開
router.post('/api/payments/subscription/:subscriptionId/resume', async (request) => {
  try {
    const { subscriptionId } = request.params;

    const stripe = new Stripe(request.env.STRIPE_SECRET_KEY);

    // サブスクリプション再開
    await stripe.subscriptions.update(subscriptionId, {
      pause_collection: null
    });

    // DB更新
    await request.env.DB.prepare(`
      UPDATE subscriptions 
      SET status = 'active', updated_at = ?
      WHERE stripe_subscription_id = ?
    `).bind(new Date().toISOString(), subscriptionId).run();

    return new Response(JSON.stringify({
      message: 'Subscription resumed successfully',
      subscription_id: subscriptionId,
      status: 'active'
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Resume subscription error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to resume subscription',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// 利用可能な割引コード一覧
router.get('/api/payments/discount-codes', async (request) => {
  try {
    const stripe = new Stripe(request.env.STRIPE_SECRET_KEY);

    // アクティブなプロモーションコード取得
    const promoCodes = await stripe.promotionCodes.list({
      active: true,
      limit: 10
    });

    const discountCodes = promoCodes.data.map(promoCode => ({
      code: promoCode.code,
      coupon: {
        id: promoCode.coupon.id,
        name: promoCode.coupon.name,
        percent_off: promoCode.coupon.percent_off,
        amount_off: promoCode.coupon.amount_off,
        currency: promoCode.coupon.currency,
        duration: promoCode.coupon.duration,
        duration_in_months: promoCode.coupon.duration_in_months
      },
      active: promoCode.active,
      expires_at: promoCode.expires_at ? new Date(promoCode.expires_at * 1000).toISOString() : null,
      max_redemptions: promoCode.max_redemptions,
      times_redeemed: promoCode.times_redeemed
    }));

    return new Response(JSON.stringify({
      discount_codes: discountCodes
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Get discount codes error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to get discount codes',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// 割引コード検証
router.post('/api/payments/validate-discount', async (request) => {
  try {
    const { code } = await request.json();

    if (!code) {
      return new Response(JSON.stringify({
        error: 'Discount code is required'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const stripe = new Stripe(request.env.STRIPE_SECRET_KEY);

    // プロモーションコード検索
    const promoCodes = await stripe.promotionCodes.list({
      code,
      limit: 1
    });

    if (promoCodes.data.length === 0) {
      return new Response(JSON.stringify({
        valid: false,
        message: '無効な割引コードです'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const promoCode = promoCodes.data[0];

    // 有効性チェック
    if (!promoCode.active) {
      return new Response(JSON.stringify({
        valid: false,
        message: 'この割引コードは利用できません'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // 使用回数チェック
    if (promoCode.max_redemptions && promoCode.times_redeemed >= promoCode.max_redemptions) {
      return new Response(JSON.stringify({
        valid: false,
        message: 'この割引コードは使用上限に達しています'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // 有効期限チェック
    if (promoCode.expires_at && promoCode.expires_at < Math.floor(Date.now() / 1000)) {
      return new Response(JSON.stringify({
        valid: false,
        message: 'この割引コードは有効期限切れです'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    return new Response(JSON.stringify({
      valid: true,
      discount: {
        code: promoCode.code,
        percent_off: promoCode.coupon.percent_off,
        amount_off: promoCode.coupon.amount_off,
        currency: promoCode.coupon.currency,
        duration: promoCode.coupon.duration,
        duration_in_months: promoCode.coupon.duration_in_months
      }
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Validate discount error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to validate discount code',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// 料金プラン一覧
router.get('/api/payments/pricing', async (request) => {
  try {
    const stripe = new Stripe(request.env.STRIPE_SECRET_KEY);

    // アクティブな料金プラン取得
    const prices = await stripe.prices.list({
      active: true,
      expand: ['data.product']
    });

    const pricingPlans = prices.data.map(price => ({
      id: price.id,
      product: {
        id: price.product.id,
        name: price.product.name,
        description: price.product.description,
        metadata: price.product.metadata
      },
      unit_amount: price.unit_amount,
      currency: price.currency,
      recurring: price.recurring,
      trial_period_days: price.recurring?.trial_period_days,
      active: price.active
    }));

    return new Response(JSON.stringify({
      pricing_plans: pricingPlans
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Get pricing error:', error);

    return new Response(JSON.stringify({
      error: 'Failed to get pricing',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Stripe webhook handler
router.post('/api/payments/webhook', async (request) => {
  try {
    const signature = request.headers.get('stripe-signature');
    const body = await request.text();

    const stripe = new Stripe(request.env.STRIPE_SECRET_KEY);
    const event = stripe.webhooks.constructEvent(
      body,
      signature,
      request.env.STRIPE_WEBHOOK_SECRET
    );

    switch (event.type) {
    case 'invoice.payment_succeeded':
      await handlePaymentSucceeded(event.data.object, request.env.DB);
      break;

    case 'invoice.payment_failed':
      await handlePaymentFailed(event.data.object, request.env.DB);
      break;

    case 'customer.subscription.updated':
      await handleSubscriptionUpdated(event.data.object, request.env.DB);
      break;

    case 'customer.subscription.deleted':
      await handleSubscriptionDeleted(event.data.object, request.env.DB);
      break;

    default:
      console.log(`Unhandled event type: ${event.type}`);
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

// Webhook helper functions
async function handlePaymentSucceeded(invoice, db) {
  // Update subscription status
  await db.prepare(
    'UPDATE subscriptions SET status = "active" WHERE stripe_subscription_id = ?'
  ).bind(invoice.subscription).run();
}

async function handlePaymentFailed(invoice, db) {
  // Update subscription status
  await db.prepare(
    'UPDATE subscriptions SET status = "past_due" WHERE stripe_subscription_id = ?'
  ).bind(invoice.subscription).run();
}

async function handleSubscriptionUpdated(subscription, db) {
  // Update subscription details
  await db.prepare(
    'UPDATE subscriptions SET status = ?, current_period_start = ?, current_period_end = ? WHERE stripe_subscription_id = ?'
  ).bind(
    subscription.status,
    new Date(subscription.current_period_start * 1000).toISOString(),
    new Date(subscription.current_period_end * 1000).toISOString(),
    subscription.id
  ).run();
}

async function handleSubscriptionDeleted(subscription, db) {
  // Update subscription status
  await db.prepare(
    'UPDATE subscriptions SET status = "canceled" WHERE stripe_subscription_id = ?'
  ).bind(subscription.id).run();
}

export { router as paymentRoutes };
