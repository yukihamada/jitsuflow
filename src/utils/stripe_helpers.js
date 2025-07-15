/**
 * Stripe helper functions for JitsuFlow (Cloudflare Workers compatible)
 * Stripe決済処理ヘルパー関数
 */

// Cloudflare Workers compatible Stripe API calls using fetch

/**
 * Helper function to make Stripe API calls
 */
async function stripeRequest(endpoint, method = 'POST', data = {}, stripeSecretKey) {
  const url = `https://api.stripe.com/v1/${endpoint}`;
  
  const formData = new URLSearchParams();
  Object.keys(data).forEach(key => {
    if (typeof data[key] === 'object') {
      formData.append(key, JSON.stringify(data[key]));
    } else {
      formData.append(key, data[key]);
    }
  });

  const response = await fetch(url, {
    method,
    headers: {
      'Authorization': `Bearer ${stripeSecretKey}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: method === 'POST' ? formData : undefined,
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Stripe API error: ${response.status} ${error}`);
  }

  return response.json();
}

/**
 * Stripe Payment Intent作成（POS決済用）
 */
export async function createPOSPaymentIntent(stripeSecretKey, {
  amount,
  currency = 'jpy',
  customerId,
  dojoId,
  items,
  metadata = {}
}) {
  try {
    const paymentIntentParams = {
      amount: Math.round(amount), // JPYは最小単位が円なので整数
      currency,
      'automatic_payment_methods[enabled]': true,
      'metadata[dojo_id]': dojoId,
      'metadata[items]': JSON.stringify(items),
      ...Object.keys(metadata).reduce((acc, key) => {
        acc[`metadata[${key}]`] = metadata[key];
        return acc;
      }, {})
    };

    // 顧客情報があれば設定
    if (customerId) {
      paymentIntentParams.customer = customerId;
    }

    const paymentIntent = await stripeRequest('payment_intents', 'POST', paymentIntentParams, stripeSecretKey);
    
    return {
      success: true,
      paymentIntent,
      clientSecret: paymentIntent.client_secret
    };
    
  } catch (error) {
    console.error('Create payment intent error:', error);
    return {
      success: false,
      error: error.message
    };
  }
}

/**
 * 決済確認とレシート生成
 */
export async function confirmPOSPayment(stripe, paymentIntentId, db, {
  dojoId,
  staffId,
  items,
  subtotal,
  taxAmount,
  discountAmount,
  totalAmount
}) {
  try {
    // Payment Intent確認
    const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);
    
    if (paymentIntent.status !== 'succeeded') {
      throw new Error('Payment not completed');
    }

    // トランザクションID生成
    const transactionId = `txn_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    // 売上記録作成
    const salesResult = await db.prepare(`
      INSERT INTO sales_transactions (
        transaction_type, dojo_id, user_id, staff_id, subtotal, 
        tax_amount, discount_amount, total_amount, payment_method, 
        items_detail, receipt_number, status, pos_transaction_id, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      'pos_sale',
      dojoId,
      paymentIntent.customer || null,
      staffId,
      subtotal,
      taxAmount,
      discountAmount,
      totalAmount,
      'credit_card',
      JSON.stringify(items),
      transactionId,
      'completed',
      paymentIntentId,
      new Date().toISOString()
    ).run();

    // 支払い記録作成
    await db.prepare(`
      INSERT INTO payments (
        payment_type, amount, tax_amount, total_amount, dojo_id, 
        user_id, status, payment_method, stripe_payment_id,
        pos_transaction_id, receipt_data, payment_date, paid_at, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      'purchase',
      subtotal,
      taxAmount,
      totalAmount,
      dojoId,
      paymentIntent.customer || null,
      'completed',
      'credit_card',
      paymentIntentId,
      transactionId,
      JSON.stringify({
        items,
        subtotal,
        tax_amount: taxAmount,
        discount_amount: discountAmount,
        total_amount: totalAmount,
        payment_method: 'credit_card'
      }),
      new Date().toISOString(),
      new Date().toISOString(),
      new Date().toISOString()
    ).run();

    return {
      success: true,
      transactionId,
      receiptData: {
        transaction_id: transactionId,
        payment_intent_id: paymentIntentId,
        amount: totalAmount,
        items,
        timestamp: new Date().toISOString()
      }
    };
    
  } catch (error) {
    console.error('Confirm POS payment error:', error);
    return {
      success: false,
      error: error.message
    };
  }
}

/**
 * 返金処理
 */
export async function createRefund(stripe, paymentIntentId, amount, reason, db) {
  try {
    // Stripe返金作成
    const refund = await stripe.refunds.create({
      payment_intent: paymentIntentId,
      amount: amount ? Math.round(amount) : undefined, // 部分返金または全額返金
      reason: reason || 'requested_by_customer'
    });

    // データベース更新
    await db.prepare(`
      UPDATE payments 
      SET refund_amount = ?, refund_reason = ?, updated_at = ?
      WHERE stripe_payment_id = ?
    `).bind(
      refund.amount,
      reason,
      new Date().toISOString(),
      paymentIntentId
    ).run();

    return {
      success: true,
      refund,
      refundId: refund.id
    };
    
  } catch (error) {
    console.error('Create refund error:', error);
    return {
      success: false,
      error: error.message
    };
  }
}

/**
 * 顧客作成または取得
 */
export async function getOrCreateCustomer(stripe, customerData, db) {
  try {
    const { email, name, phone, userId } = customerData;
    
    // 既存の顧客確認
    if (userId) {
      const user = await db.prepare(
        'SELECT stripe_customer_id FROM users WHERE id = ?'
      ).bind(userId).first();
      
      if (user && user.stripe_customer_id) {
        const customer = await stripe.customers.retrieve(user.stripe_customer_id);
        return {
          success: true,
          customer,
          isNew: false
        };
      }
    }

    // 新規顧客作成
    const customer = await stripe.customers.create({
      email,
      name,
      phone,
      metadata: {
        user_id: userId || ''
      }
    });

    // データベース更新
    if (userId) {
      await db.prepare(
        'UPDATE users SET stripe_customer_id = ? WHERE id = ?'
      ).bind(customer.id, userId).run();
    }

    return {
      success: true,
      customer,
      isNew: true
    };
    
  } catch (error) {
    console.error('Get or create customer error:', error);
    return {
      success: false,
      error: error.message
    };
  }
}

/**
 * サブスクリプション作成・変更
 */
export async function createOrUpdateSubscription(stripe, {
  customerId,
  priceId,
  currentSubscriptionId,
  paymentMethodId,
  prorationBehavior = 'create_prorations'
}) {
  try {
    // 既存サブスクリプションがある場合は更新
    if (currentSubscriptionId) {
      const subscription = await stripe.subscriptions.update(currentSubscriptionId, {
        items: [{
          price: priceId
        }],
        proration_behavior: prorationBehavior
      });
      
      return {
        success: true,
        subscription,
        isNew: false
      };
    }

    // 新規サブスクリプション作成
    const subscription = await stripe.subscriptions.create({
      customer: customerId,
      items: [{
        price: priceId
      }],
      default_payment_method: paymentMethodId,
      expand: ['latest_invoice.payment_intent']
    });

    return {
      success: true,
      subscription,
      isNew: true
    };
    
  } catch (error) {
    console.error('Create or update subscription error:', error);
    return {
      success: false,
      error: error.message
    };
  }
}

/**
 * レシート生成
 */
export function generateReceipt({
  transactionId,
  dojoName,
  items,
  subtotal,
  taxAmount,
  discountAmount,
  totalAmount,
  paymentMethod,
  timestamp,
  customerName
}) {
  const receiptData = {
    receipt_number: transactionId,
    dojo_name: dojoName,
    date: new Date(timestamp).toLocaleDateString('ja-JP'),
    time: new Date(timestamp).toLocaleTimeString('ja-JP'),
    customer_name: customerName || 'ゲスト',
    items: items.map(item => ({
      name: item.item_name || item.name,
      quantity: item.quantity,
      unit_price: item.unit_price,
      total_price: item.total_price
    })),
    subtotal,
    tax_amount: taxAmount,
    discount_amount: discountAmount,
    total_amount: totalAmount,
    payment_method: paymentMethod === 'credit_card' ? 'クレジットカード' : paymentMethod,
    footer_message: 'ありがとうございました。またのご利用をお待ちしております。'
  };

  return receiptData;
}

/**
 * Webhook署名検証
 */
export function verifyWebhookSignature(body, signature, webhookSecret) {
  try {
    const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);
    const event = stripe.webhooks.constructEvent(body, signature, webhookSecret);
    return {
      success: true,
      event
    };
  } catch (error) {
    console.error('Webhook signature verification failed:', error);
    return {
      success: false,
      error: error.message
    };
  }
}