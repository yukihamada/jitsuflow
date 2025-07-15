/**
 * 商品管理API
 * JitsuFlowショップの商品CRUD操作
 */

import { Router } from 'itty-router';
import { corsHeaders } from '../middleware/cors';

const router = Router();

// 商品一覧取得
router.get('/api/products', async (request) => {
  try {
    const url = new URL(request.url);
    const category = url.searchParams.get('category');
    const limit = parseInt(url.searchParams.get('limit')) || 20;
    const offset = parseInt(url.searchParams.get('offset')) || 0;
    
    let query = 'SELECT * FROM products WHERE is_active = 1';
    const params = [];
    
    if (category) {
      query += ' AND category = ?';
      params.push(category);
    }
    
    query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
    params.push(limit, offset);
    
    const result = await request.env.DB.prepare(query).bind(...params).all();
    
    // Parse JSON attributes for each product
    const products = result.results.map(product => ({
      ...product,
      attributes: product.attributes ? JSON.parse(product.attributes) : null
    }));
    
    return new Response(JSON.stringify({
      products: products
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Get products error:', error);
    
    return new Response(JSON.stringify({
      error: 'Failed to get products',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// カート取得
router.get('/api/cart', async (request) => {
  try {
    const userId = request.user.userId;
    
    const result = await request.env.DB.prepare(`
      SELECT 
        sc.*,
        p.name as product_name,
        p.price,
        p.description,
        p.category,
        p.image_url,
        p.stock_quantity,
        p.size,
        p.color,
        p.attributes
      FROM shopping_carts sc
      JOIN products p ON sc.product_id = p.id
      WHERE sc.user_id = ?
      ORDER BY sc.created_at DESC
    `).bind(userId).all();
    
    const items = result.results.map(item => ({
      product: {
        id: item.product_id,
        name: item.product_name,
        price: item.price,
        description: item.description,
        category: item.category,
        image_url: item.image_url,
        stock_quantity: item.stock_quantity,
        size: item.size,
        color: item.color,
        attributes: item.attributes ? JSON.parse(item.attributes) : null,
        created_at: item.created_at,
        updated_at: item.updated_at
      },
      quantity: item.quantity
    }));
    
    return new Response(JSON.stringify({
      items: items
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Get cart error:', error);
    
    return new Response(JSON.stringify({
      error: 'Failed to get cart',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// カートに追加
router.post('/api/cart/add', async (request) => {
  try {
    const { product_id, quantity } = await request.json();
    const userId = request.user.userId;
    
    // 在庫確認
    const product = await request.env.DB.prepare(
      'SELECT stock_quantity FROM products WHERE id = ?'
    ).bind(product_id).first();
    
    if (!product || product.stock_quantity < quantity) {
      return new Response(JSON.stringify({
        error: 'Insufficient stock'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // カートに追加または更新
    await request.env.DB.prepare(`
      INSERT INTO shopping_carts (user_id, product_id, quantity)
      VALUES (?, ?, ?)
      ON CONFLICT(user_id, product_id) DO UPDATE SET
        quantity = quantity + excluded.quantity,
        updated_at = CURRENT_TIMESTAMP
    `).bind(userId, product_id, quantity).run();
    
    return new Response(JSON.stringify({
      message: 'Added to cart'
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Add to cart error:', error);
    
    return new Response(JSON.stringify({
      error: 'Failed to add to cart',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// カート更新
router.post('/api/cart/update', async (request) => {
  try {
    const { product_id, quantity } = await request.json();
    const userId = request.user.userId;
    
    if (quantity <= 0) {
      // 数量が0以下の場合は削除
      await request.env.DB.prepare(
        'DELETE FROM shopping_carts WHERE user_id = ? AND product_id = ?'
      ).bind(userId, product_id).run();
    } else {
      // 在庫確認
      const product = await request.env.DB.prepare(
        'SELECT stock_quantity FROM products WHERE id = ?'
      ).bind(product_id).first();
      
      if (!product || product.stock_quantity < quantity) {
        return new Response(JSON.stringify({
          error: 'Insufficient stock'
        }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });
      }
      
      // カート更新
      await request.env.DB.prepare(`
        UPDATE shopping_carts 
        SET quantity = ?, updated_at = CURRENT_TIMESTAMP
        WHERE user_id = ? AND product_id = ?
      `).bind(quantity, userId, product_id).run();
    }
    
    return new Response(JSON.stringify({
      message: 'Cart updated'
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Update cart error:', error);
    
    return new Response(JSON.stringify({
      error: 'Failed to update cart',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// カートから削除
router.delete('/api/cart/remove/:productId', async (request) => {
  try {
    const { productId } = request.params;
    const userId = request.user.userId;
    
    await request.env.DB.prepare(
      'DELETE FROM shopping_carts WHERE user_id = ? AND product_id = ?'
    ).bind(userId, productId).run();
    
    return new Response(JSON.stringify({
      message: 'Removed from cart'
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Remove from cart error:', error);
    
    return new Response(JSON.stringify({
      error: 'Failed to remove from cart',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// 注文作成
router.post('/api/orders/create', async (request) => {
  try {
    const { items, shipping_address, payment_method, subtotal, tax, total } = await request.json();
    const userId = request.user.userId;
    
    // トランザクション開始
    const db = request.env.DB;
    
    // 注文作成
    const orderResult = await db.prepare(`
      INSERT INTO orders (
        user_id, subtotal, tax, total, status,
        shipping_address, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
    `).bind(
      userId,
      subtotal,
      tax,
      total,
      'pending',
      JSON.stringify(shipping_address),
      new Date().toISOString()
    ).run();
    
    const orderId = orderResult.meta.last_row_id;
    
    // 注文アイテム作成
    for (const item of items) {
      const product = await db.prepare(
        'SELECT name, price FROM products WHERE id = ?'
      ).bind(item.product_id).first();
      
      await db.prepare(`
        INSERT INTO order_items (
          order_id, product_id, product_name,
          unit_price, quantity, total_price
        ) VALUES (?, ?, ?, ?, ?, ?)
      `).bind(
        orderId,
        item.product_id,
        product.name,
        product.price,
        item.quantity,
        product.price * item.quantity
      ).run();
      
      // 在庫更新
      await db.prepare(`
        UPDATE products 
        SET stock_quantity = stock_quantity - ?
        WHERE id = ?
      `).bind(item.quantity, item.product_id).run();
    }
    
    // カートクリア
    await db.prepare(
      'DELETE FROM shopping_carts WHERE user_id = ?'
    ).bind(userId).run();
    
    return new Response(JSON.stringify({
      order_id: orderId,
      message: 'Order created successfully'
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

// 注文履歴取得
router.get('/api/orders/user/:userId', async (request) => {
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
    
    const orders = await request.env.DB.prepare(`
      SELECT o.*, COUNT(oi.id) as item_count
      FROM orders o
      LEFT JOIN order_items oi ON o.id = oi.order_id
      WHERE o.user_id = ?
      GROUP BY o.id
      ORDER BY o.created_at DESC
    `).bind(userId).all();
    
    return new Response(JSON.stringify({
      orders: orders.results
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Get user orders error:', error);
    
    return new Response(JSON.stringify({
      error: 'Failed to get orders',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

export { router as productRoutes };