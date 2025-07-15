/**
 * JitsuFlow Cloudflare Workers API - Complete Implementation
 * All routes directly implemented to avoid module import issues
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

// Helper functions
function createToken(payload) {
  const data = JSON.stringify({
    ...payload,
    exp: Date.now() + 86400000 // 24 hours
  });
  return btoa(data);
}

function parseToken(token) {
  try {
    const data = JSON.parse(atob(token));
    if (data.exp < Date.now()) {
      throw new Error('Token expired');
    }
    return data;
  } catch (error) {
    throw new Error('Invalid token');
  }
}

function hashPassword(password) {
  // Simple hash for demo - replace with proper implementation in production
  return btoa(password);
}

function verifyPassword(password, hash) {
  return hashPassword(password) === hash;
}

// Auth middleware
async function requireAuth(request) {
  const authHeader = request.headers.get('Authorization');
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return new Response(JSON.stringify({
      error: 'Unauthorized',
      message: 'Missing or invalid authorization header'
    }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  try {
    const token = authHeader.substring(7);
    const payload = parseToken(token);
    request.user = payload;
  } catch (error) {
    return new Response(JSON.stringify({
      error: 'Unauthorized',
      message: error.message
    }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
}

// CORS preflight
router.options('*', () => new Response(null, { headers: corsHeaders }));

// Health check
router.get('/api/health', () => {
  return new Response(JSON.stringify({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    service: 'JitsuFlow API'
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
});

// User Registration
router.post('/api/users/register', async (request) => {
  try {
    const { email, password, name, phone } = await request.json();
    
    if (!email || !password || !name) {
      return new Response(JSON.stringify({
        error: 'Missing required fields',
        message: 'Email, password, and name are required'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // Check if user exists
    const existingUser = await request.env.DB.prepare(
      'SELECT id FROM users WHERE email = ?'
    ).bind(email).first();
    
    if (existingUser) {
      return new Response(JSON.stringify({
        error: 'User already exists',
        message: 'Email is already registered'
      }), {
        status: 409,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // Create user
    const hashedPassword = hashPassword(password);
    const result = await request.env.DB.prepare(
      'INSERT INTO users (email, password_hash, name, phone, role, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)'
    ).bind(
      email,
      hashedPassword,
      name,
      phone || null,
      'user',
      new Date().toISOString(),
      new Date().toISOString()
    ).run();
    
    const userId = result.meta.last_row_id;
    const token = createToken({ userId, email, role: 'user' });
    
    return new Response(JSON.stringify({
      message: 'Registration successful',
      user: {
        id: userId,
        email,
        name,
        phone
      },
      token
    }), {
      status: 201,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Registration error:', error);
    return new Response(JSON.stringify({
      error: 'Registration failed',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// User Login
router.post('/api/users/login', async (request) => {
  try {
    const { email, password } = await request.json();
    
    if (!email || !password) {
      return new Response(JSON.stringify({
        error: 'Missing credentials',
        message: 'Email and password are required'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    const user = await request.env.DB.prepare(
      'SELECT * FROM users WHERE email = ?'
    ).bind(email).first();
    
    if (!user || !verifyPassword(password, user.password_hash)) {
      return new Response(JSON.stringify({
        error: 'Invalid credentials',
        message: 'Email or password is incorrect'
      }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    const token = createToken({ 
      userId: user.id, 
      email: user.email, 
      role: user.role || 'user' 
    });
    
    return new Response(JSON.stringify({
      message: 'Login successful',
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        phone: user.phone
      },
      token
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Login error:', error);
    return new Response(JSON.stringify({
      error: 'Login failed',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Get Products
router.get('/api/products', async (request) => {
  const authResponse = await requireAuth(request);
  if (authResponse) return authResponse;
  
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
    
    return new Response(JSON.stringify({
      products: result.results || []
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

// Get Cart
router.get('/api/cart', async (request) => {
  const authResponse = await requireAuth(request);
  if (authResponse) return authResponse;
  
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
        p.stock_quantity
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
        stock_quantity: item.stock_quantity
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

// Add to Cart
router.post('/api/cart/add', async (request) => {
  const authResponse = await requireAuth(request);
  if (authResponse) return authResponse;
  
  try {
    const { product_id, quantity } = await request.json();
    const userId = request.user.userId;
    
    // Check stock
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
    
    // Add to cart
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

// Get Dojos
router.get('/api/dojos', async (request) => {
  const authResponse = await requireAuth(request);
  if (authResponse) return authResponse;
  
  try {
    const result = await request.env.DB.prepare(
      'SELECT * FROM dojos ORDER BY name'
    ).all();
    
    return new Response(JSON.stringify({
      dojos: result.results || []
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Get dojos error:', error);
    return new Response(JSON.stringify({
      error: 'Failed to get dojos',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Create Booking
router.post('/api/dojo/bookings', async (request) => {
  const authResponse = await requireAuth(request);
  if (authResponse) return authResponse;
  
  try {
    const { dojo_id, class_type, booking_date, booking_time } = await request.json();
    const userId = request.user.userId;
    
    const result = await request.env.DB.prepare(`
      INSERT INTO bookings (user_id, dojo_id, class_type, booking_date, booking_time, status, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      userId,
      dojo_id,
      class_type,
      booking_date,
      booking_time,
      'confirmed',
      new Date().toISOString(),
      new Date().toISOString()
    ).run();
    
    const bookingId = result.meta.last_row_id;
    
    return new Response(JSON.stringify({
      booking: {
        id: bookingId,
        user_id: userId,
        dojo_id,
        class_type,
        booking_date,
        booking_time,
        status: 'confirmed'
      }
    }), {
      status: 201,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Create booking error:', error);
    return new Response(JSON.stringify({
      error: 'Failed to create booking',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Get Bookings
router.get('/api/dojo/bookings', async (request) => {
  const authResponse = await requireAuth(request);
  if (authResponse) return authResponse;
  
  try {
    const userId = request.user.userId;
    
    const result = await request.env.DB.prepare(`
      SELECT b.*, d.name as dojo_name
      FROM bookings b
      JOIN dojos d ON b.dojo_id = d.id
      WHERE b.user_id = ?
      ORDER BY b.booking_date DESC, b.booking_time DESC
    `).bind(userId).all();
    
    return new Response(JSON.stringify({
      bookings: result.results || []
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Get bookings error:', error);
    return new Response(JSON.stringify({
      error: 'Failed to get bookings',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Get Videos
router.get('/api/videos', async (request) => {
  const authResponse = await requireAuth(request);
  if (authResponse) return authResponse;
  
  try {
    const url = new URL(request.url);
    const premium = url.searchParams.get('premium');
    
    let query = 'SELECT * FROM videos WHERE status = "published"';
    const params = [];
    
    if (premium !== null) {
      query += ' AND is_premium = ?';
      params.push(premium === 'true' ? 1 : 0);
    }
    
    query += ' ORDER BY created_at DESC';
    
    const result = await request.env.DB.prepare(query).bind(...params).all();
    
    return new Response(JSON.stringify({
      videos: result.results || []
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Get videos error:', error);
    return new Response(JSON.stringify({
      error: 'Failed to get videos',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Get Rentals
router.get('/api/dojo-mode/:dojoId/rentals', async (request) => {
  const authResponse = await requireAuth(request);
  if (authResponse) return authResponse;
  
  try {
    const { dojoId } = request.params;
    
    const result = await request.env.DB.prepare(
      'SELECT * FROM rentals WHERE dojo_id = ? AND status = "available" ORDER BY item_name'
    ).bind(dojoId).all();
    
    return new Response(JSON.stringify({
      rentals: result.results || []
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

// Create Rental Transaction
router.post('/api/rentals/:rentalId/rent', async (request) => {
  const authResponse = await requireAuth(request);
  if (authResponse) return authResponse;
  
  try {
    const { rentalId } = request.params;
    const { user_id, return_due_date } = await request.json();
    
    // Check availability
    const rental = await request.env.DB.prepare(
      'SELECT available_quantity FROM rentals WHERE id = ?'
    ).bind(rentalId).first();
    
    if (!rental || rental.available_quantity < 1) {
      return new Response(JSON.stringify({
        error: 'Rental not available'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // Create transaction
    const result = await request.env.DB.prepare(`
      INSERT INTO rental_transactions (rental_id, user_id, rental_date, return_due_date, status)
      VALUES (?, ?, ?, ?, ?)
    `).bind(
      rentalId,
      user_id,
      new Date().toISOString(),
      return_due_date,
      'active'
    ).run();
    
    // Update availability
    await request.env.DB.prepare(
      'UPDATE rentals SET available_quantity = available_quantity - 1 WHERE id = ?'
    ).bind(rentalId).run();
    
    return new Response(JSON.stringify({
      transaction: {
        id: result.meta.last_row_id,
        rental_id: rentalId,
        user_id,
        rental_date: new Date().toISOString(),
        return_due_date,
        status: 'active'
      }
    }), {
      status: 201,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Create rental error:', error);
    return new Response(JSON.stringify({
      error: 'Failed to create rental',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// 404 handler
router.all('*', () => new Response('Not Found', { 
  status: 404,
  headers: corsHeaders
}));

export default {
  async fetch(request, env, ctx) {
    try {
      request.env = env;
      request.ctx = ctx;
      return await router.handle(request);
    } catch (error) {
      console.error('Worker error:', error);
      return new Response(JSON.stringify({
        error: 'Internal Server Error',
        message: error.message
      }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
  }
};