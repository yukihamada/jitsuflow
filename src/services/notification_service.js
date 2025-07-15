/**
 * Notification Service for JitsuFlow
 * Handles email, push notifications, and Slack integration
 */

// Send email using Resend API
export async function sendEmail(resendApiKey, { to, subject, html, from = 'JitsuFlow <noreply@jitsuflow.app>' }) {
  try {
    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${resendApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from,
        to,
        subject,
        html,
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`Resend API error: ${error}`);
    }

    const result = await response.json();
    return { success: true, id: result.id };
  } catch (error) {
    console.error('Send email error:', error);
    return { success: false, error: error.message };
  }
}

// Send Slack notification
export async function sendSlackNotification(webhookUrl, message) {
  try {
    const response = await fetch(webhookUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        text: message.text,
        blocks: message.blocks,
        attachments: message.attachments,
      }),
    });

    if (!response.ok) {
      throw new Error(`Slack webhook error: ${response.statusText}`);
    }

    return { success: true };
  } catch (error) {
    console.error('Send Slack notification error:', error);
    return { success: false, error: error.message };
  }
}

// Create notification in database
export async function createNotification(db, { userId, type, title, message, data }) {
  try {
    const result = await db.prepare(`
      INSERT INTO notifications (user_id, type, title, message, data, created_at)
      VALUES (?, ?, ?, ?, ?, ?)
    `).bind(
      userId,
      type,
      title,
      message,
      data ? JSON.stringify(data) : null,
      new Date().toISOString()
    ).run();

    return { success: true, id: result.meta.last_row_id };
  } catch (error) {
    console.error('Create notification error:', error);
    return { success: false, error: error.message };
  }
}

// Email templates
export const emailTemplates = {
  bookingConfirmation: ({ userName, dojoName, classType, bookingDate, bookingTime }) => ({
    subject: '予約確認 - JitsuFlow',
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: -apple-system, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #2563eb; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
          .content { background: #f8f9fa; padding: 30px; border-radius: 0 0 8px 8px; }
          .booking-details { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; }
          .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>予約が確定しました</h1>
          </div>
          <div class="content">
            <p>こんにちは、${userName}様</p>
            <p>以下の内容で予約が確定しました：</p>
            
            <div class="booking-details">
              <h3>予約詳細</h3>
              <p><strong>道場：</strong> ${dojoName}</p>
              <p><strong>クラス：</strong> ${classType}</p>
              <p><strong>日付：</strong> ${bookingDate}</p>
              <p><strong>時間：</strong> ${bookingTime}</p>
            </div>
            
            <p>当日は開始時間の10分前までにお越しください。</p>
            <p>キャンセルの場合は、24時間前までにアプリから手続きをお願いします。</p>
          </div>
          <div class="footer">
            <p>© 2025 JitsuFlow. All rights reserved.</p>
          </div>
        </div>
      </body>
      </html>
    `
  }),

  bookingReminder: ({ userName, dojoName, classType, bookingDate, bookingTime }) => ({
    subject: '明日の予約リマインダー - JitsuFlow',
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: -apple-system, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #f59e0b; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
          .content { background: #f8f9fa; padding: 30px; border-radius: 0 0 8px 8px; }
          .reminder-box { background: #fff3cd; border: 1px solid #ffc107; padding: 15px; border-radius: 8px; margin: 20px 0; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>明日の予約リマインダー</h1>
          </div>
          <div class="content">
            <p>こんにちは、${userName}様</p>
            
            <div class="reminder-box">
              <h3>🔔 明日の予約</h3>
              <p><strong>道場：</strong> ${dojoName}</p>
              <p><strong>クラス：</strong> ${classType}</p>
              <p><strong>日付：</strong> ${bookingDate}</p>
              <p><strong>時間：</strong> ${bookingTime}</p>
            </div>
            
            <p>準備をお忘れなく！</p>
          </div>
        </div>
      </body>
      </html>
    `
  }),

  orderConfirmation: ({ userName, orderNumber, totalAmount, items }) => ({
    subject: `注文確認 #${orderNumber} - JitsuFlow`,
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: -apple-system, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #10b981; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
          .content { background: #f8f9fa; padding: 30px; border-radius: 0 0 8px 8px; }
          .order-items { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; }
          .item { border-bottom: 1px solid #eee; padding: 10px 0; }
          .total { font-size: 20px; font-weight: bold; text-align: right; margin-top: 20px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>ご注文ありがとうございます</h1>
          </div>
          <div class="content">
            <p>こんにちは、${userName}様</p>
            <p>ご注文を承りました。注文番号: <strong>${orderNumber}</strong></p>
            
            <div class="order-items">
              <h3>注文内容</h3>
              ${items.map(item => `
                <div class="item">
                  <p><strong>${item.name}</strong></p>
                  <p>数量: ${item.quantity} × ¥${item.price.toLocaleString()} = ¥${(item.quantity * item.price).toLocaleString()}</p>
                </div>
              `).join('')}
              <div class="total">
                合計: ¥${totalAmount.toLocaleString()}
              </div>
            </div>
            
            <p>商品の発送準備が整い次第、改めてご連絡いたします。</p>
          </div>
        </div>
      </body>
      </html>
    `
  }),

  subscriptionWelcome: ({ userName, planName, trialEndDate }) => ({
    subject: 'プレミアムメンバーシップへようこそ - JitsuFlow',
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: -apple-system, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
          .content { background: #f8f9fa; padding: 30px; border-radius: 0 0 8px 8px; }
          .benefits { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🎉 プレミアムメンバーへようこそ！</h1>
          </div>
          <div class="content">
            <p>こんにちは、${userName}様</p>
            <p><strong>${planName}</strong>プランへのご登録ありがとうございます。</p>
            
            <div class="benefits">
              <h3>プレミアム特典</h3>
              <ul>
                <li>予約回数無制限</li>
                <li>限定動画コンテンツへのアクセス</li>
                <li>ライブ配信への参加権</li>
                <li>優先予約機能</li>
                <li>特別イベントへの招待</li>
              </ul>
            </div>
            
            <p><strong>無料トライアル期間：</strong> ${trialEndDate}まで</p>
            <p>トライアル期間中はいつでもキャンセル可能です。</p>
          </div>
        </div>
      </body>
      </html>
    `
  })
};

// Slack message templates
export const slackTemplates = {
  newBooking: ({ dojoName, userName, classType, bookingDate, bookingTime }) => ({
    text: `新規予約: ${userName}様が${bookingDate} ${bookingTime}の${classType}クラスを予約しました`,
    blocks: [
      {
        type: 'header',
        text: {
          type: 'plain_text',
          text: '📅 新規予約通知'
        }
      },
      {
        type: 'section',
        fields: [
          { type: 'mrkdwn', text: `*道場:*\n${dojoName}` },
          { type: 'mrkdwn', text: `*お客様:*\n${userName}` },
          { type: 'mrkdwn', text: `*クラス:*\n${classType}` },
          { type: 'mrkdwn', text: `*日時:*\n${bookingDate} ${bookingTime}` }
        ]
      }
    ]
  }),

  newOrder: ({ orderNumber, userName, totalAmount, itemCount }) => ({
    text: `新規注文: ${userName}様から¥${totalAmount.toLocaleString()}の注文`,
    blocks: [
      {
        type: 'header',
        text: {
          type: 'plain_text',
          text: '🛍️ 新規注文通知'
        }
      },
      {
        type: 'section',
        fields: [
          { type: 'mrkdwn', text: `*注文番号:*\n${orderNumber}` },
          { type: 'mrkdwn', text: `*お客様:*\n${userName}` },
          { type: 'mrkdwn', text: `*商品数:*\n${itemCount}点` },
          { type: 'mrkdwn', text: `*合計金額:*\n¥${totalAmount.toLocaleString()}` }
        ]
      },
      {
        type: 'actions',
        elements: [
          {
            type: 'button',
            text: { type: 'plain_text', text: '注文詳細を見る' },
            url: `https://admin.jitsuflow.app/orders/${orderNumber}`
          }
        ]
      }
    ]
  }),

  lowStock: ({ productName, currentStock, threshold }) => ({
    text: `在庫警告: ${productName}の在庫が残り${currentStock}個になりました`,
    blocks: [
      {
        type: 'header',
        text: {
          type: 'plain_text',
          text: '⚠️ 在庫警告'
        }
      },
      {
        type: 'section',
        text: {
          type: 'mrkdwn',
          text: `*${productName}* の在庫が少なくなっています。`
        }
      },
      {
        type: 'section',
        fields: [
          { type: 'mrkdwn', text: `*現在の在庫:*\n${currentStock}個` },
          { type: 'mrkdwn', text: `*警告閾値:*\n${threshold}個` }
        ]
      },
      {
        type: 'actions',
        elements: [
          {
            type: 'button',
            text: { type: 'plain_text', text: '在庫を補充' },
            style: 'primary',
            url: 'https://admin.jitsuflow.app/inventory'
          }
        ]
      }
    ]
  })
};

// Notification service class
export class NotificationService {
  constructor(env) {
    this.env = env;
  }

  // Send booking confirmation
  async sendBookingConfirmation(booking, user, dojo) {
    // Save to database
    await createNotification(this.env.DB, {
      userId: user.id,
      type: 'booking_confirmation',
      title: '予約確認',
      message: `${dojo.name}での${booking.class_type}クラスの予約が確定しました`,
      data: { bookingId: booking.id }
    });

    // Send email
    const emailTemplate = emailTemplates.bookingConfirmation({
      userName: user.name,
      dojoName: dojo.name,
      classType: booking.class_type,
      bookingDate: booking.booking_date,
      bookingTime: booking.booking_time
    });

    await sendEmail(this.env.RESEND_API_KEY, {
      to: user.email,
      ...emailTemplate
    });

    // Send Slack notification to dojo
    if (dojo.slack_webhook_url) {
      const slackMessage = slackTemplates.newBooking({
        dojoName: dojo.name,
        userName: user.name,
        classType: booking.class_type,
        bookingDate: booking.booking_date,
        bookingTime: booking.booking_time
      });

      await sendSlackNotification(dojo.slack_webhook_url, slackMessage);
    }
  }

  // Send order confirmation
  async sendOrderConfirmation(order, user, items) {
    // Save to database
    await createNotification(this.env.DB, {
      userId: user.id,
      type: 'order_confirmation',
      title: '注文確認',
      message: `注文 #${order.order_number} を承りました`,
      data: { orderId: order.id }
    });

    // Send email
    const emailTemplate = emailTemplates.orderConfirmation({
      userName: user.name,
      orderNumber: order.order_number,
      totalAmount: order.total_amount,
      items: items
    });

    await sendEmail(this.env.RESEND_API_KEY, {
      to: user.email,
      ...emailTemplate
    });

    // Send Slack notification
    if (this.env.SLACK_WEBHOOK_URL) {
      const slackMessage = slackTemplates.newOrder({
        orderNumber: order.order_number,
        userName: user.name,
        totalAmount: order.total_amount,
        itemCount: items.length
      });

      await sendSlackNotification(this.env.SLACK_WEBHOOK_URL, slackMessage);
    }
  }

  // Send booking reminder (to be called by cron job)
  async sendBookingReminders() {
    // Get tomorrow's bookings
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const tomorrowDate = tomorrow.toISOString().split('T')[0];

    const bookings = await this.env.DB.prepare(`
      SELECT b.*, u.email, u.name as user_name, d.name as dojo_name
      FROM bookings b
      JOIN users u ON b.user_id = u.id
      JOIN dojos d ON b.dojo_id = d.id
      WHERE b.booking_date = ? AND b.status = 'confirmed'
    `).bind(tomorrowDate).all();

    for (const booking of bookings.results) {
      const emailTemplate = emailTemplates.bookingReminder({
        userName: booking.user_name,
        dojoName: booking.dojo_name,
        classType: booking.class_type,
        bookingDate: booking.booking_date,
        bookingTime: booking.booking_time
      });

      await sendEmail(this.env.RESEND_API_KEY, {
        to: booking.email,
        ...emailTemplate
      });

      await createNotification(this.env.DB, {
        userId: booking.user_id,
        type: 'booking_reminder',
        title: '予約リマインダー',
        message: `明日の${booking.class_type}クラスの予約をお忘れなく`,
        data: { bookingId: booking.id }
      });
    }
  }

  // Check and notify low stock
  async checkLowStock() {
    const lowStockProducts = await this.env.DB.prepare(`
      SELECT * FROM products 
      WHERE stock_quantity <= 10 AND is_active = 1
    `).all();

    for (const product of lowStockProducts.results) {
      if (this.env.SLACK_WEBHOOK_URL) {
        const slackMessage = slackTemplates.lowStock({
          productName: product.name,
          currentStock: product.stock_quantity,
          threshold: 10
        });

        await sendSlackNotification(this.env.SLACK_WEBHOOK_URL, slackMessage);
      }
    }
  }
}
