/**
 * JitsuFlow Cloudflare Workers API - Enhanced Implementation
 * Fixed authentication, validation, and added security features
 */

import { Router } from 'itty-router';
import { paymentRoutes } from './routes/stripe_payments.js';
import * as adminRoutes from './routes/admin.js';
import { instructorsAdminRoutes } from './routes/instructors-admin.js';

const router = Router();

// CORS headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Requested-With',
  'Access-Control-Max-Age': '86400'
};

// Rate limiting store
const rateLimitStore = new Map();

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

// Input validation helpers
function validateEmail(email) {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

function validatePassword(password) {
  return password && password.length >= 8;
}

function sanitizeInput(input) {
  if (typeof input !== 'string') return input;
  // Remove potential XSS attempts
  return input
    .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
    .replace(/javascript:/gi, '')
    .replace(/on\w+\s*=/gi, '');
}

// Rate limiting middleware
async function rateLimitMiddleware(request) {
  const clientIp = request.headers.get('CF-Connecting-IP') ||
                   request.headers.get('X-Forwarded-For') ||
                   'unknown';

  const now = Date.now();
  const windowMs = 60000; // 1 minute
  const maxRequests = 100;

  // Clean old entries
  for (const [key, data] of rateLimitStore.entries()) {
    if (now - data.firstRequest > windowMs) {
      rateLimitStore.delete(key);
    }
  }

  const clientData = rateLimitStore.get(clientIp) || { count: 0, firstRequest: now };

  if (clientData.count >= maxRequests && now - clientData.firstRequest < windowMs) {
    return new Response(JSON.stringify({
      error: 'Too Many Requests',
      message: `Rate limit exceeded. Max ${maxRequests} requests per minute.`,
      retryAfter: Math.ceil((clientData.firstRequest + windowMs - now) / 1000)
    }), {
      status: 429,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json',
        'X-RateLimit-Limit': maxRequests.toString(),
        'X-RateLimit-Remaining': '0',
        'X-RateLimit-Reset': new Date(clientData.firstRequest + windowMs).toISOString(),
        'Retry-After': Math.ceil((clientData.firstRequest + windowMs - now) / 1000).toString()
      }
    });
  }

  clientData.count++;
  rateLimitStore.set(clientIp, clientData);

  // Add rate limit info to request
  request.rateLimitInfo = {
    limit: maxRequests,
    remaining: maxRequests - clientData.count,
    reset: new Date(clientData.firstRequest + windowMs).toISOString()
  };
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
    service: 'JitsuFlow API',
    version: '1.1.0' // Updated version
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
});

// User Registration with enhanced validation
router.post('/api/users/register', async (request) => {
  try {
    const body = await request.json();
    const { email, password, name, phone } = body;

    // Validate required fields
    const errors = [];

    if (!email || !validateEmail(email)) {
      errors.push('Valid email address is required');
    }

    if (!password || !validatePassword(password)) {
      errors.push('Password must be at least 8 characters long');
    }

    if (!name || name.trim().length < 2) {
      errors.push('Name must be at least 2 characters long');
    }

    if (phone && !/^[\d\s\-+()]+$/.test(phone)) {
      errors.push('Invalid phone number format');
    }

    if (errors.length > 0) {
      return new Response(JSON.stringify({
        error: 'Validation failed',
        message: 'Please fix the following errors',
        errors: errors
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Sanitize inputs
    const sanitizedEmail = sanitizeInput(email).toLowerCase();
    const sanitizedName = sanitizeInput(name.trim());
    const sanitizedPhone = phone ? sanitizeInput(phone) : null;

    // Check if user exists
    const existingUser = await request.env.DB.prepare(
      'SELECT id FROM users WHERE email = ?'
    ).bind(sanitizedEmail).first();

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
      sanitizedEmail,
      hashedPassword,
      sanitizedName,
      sanitizedPhone,
      'user',
      new Date().toISOString(),
      new Date().toISOString()
    ).run();

    const userId = result.meta.last_row_id;
    const token = createToken({ userId, email: sanitizedEmail, role: 'user' });

    return new Response(JSON.stringify({
      message: 'Registration successful',
      user: {
        id: userId,
        email: sanitizedEmail,
        name: sanitizedName,
        phone: sanitizedPhone
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

    const sanitizedEmail = sanitizeInput(email).toLowerCase();

    const user = await request.env.DB.prepare(
      'SELECT * FROM users WHERE email = ? AND is_active = 1'
    ).bind(sanitizedEmail).first();

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
        phone: user.phone,
        role: user.role || 'user'
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

// Update User Profile
router.put('/api/users/profile', async (request) => {
  const authResponse = await requireAuth(request);
  if (authResponse) return authResponse;

  try {
    const { name, phone } = await request.json();
    const userId = request.user.userId;

    const updates = [];
    const values = [];

    if (name !== undefined) {
      if (name.trim().length < 2) {
        return new Response(JSON.stringify({
          error: 'Validation failed',
          message: 'Name must be at least 2 characters long'
        }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });
      }
      updates.push('name = ?');
      values.push(sanitizeInput(name.trim()));
    }

    if (phone !== undefined) {
      if (phone && !/^[\d\s\-+()]+$/.test(phone)) {
        return new Response(JSON.stringify({
          error: 'Validation failed',
          message: 'Invalid phone number format'
        }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });
      }
      updates.push('phone = ?');
      values.push(phone ? sanitizeInput(phone) : null);
    }

    if (updates.length === 0) {
      return new Response(JSON.stringify({
        error: 'No fields to update'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    updates.push('updated_at = ?');
    values.push(new Date().toISOString());
    values.push(userId);

    await request.env.DB.prepare(
      `UPDATE users SET ${updates.join(', ')} WHERE id = ?`
    ).bind(...values).run();

    // Get updated user
    const updatedUser = await request.env.DB.prepare(
      'SELECT id, email, name, phone FROM users WHERE id = ?'
    ).bind(userId).first();

    return new Response(JSON.stringify({
      message: 'Profile updated successfully',
      user: updatedUser
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Update profile error:', error);
    return new Response(JSON.stringify({
      error: 'Failed to update profile',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Admin Routes - User Management
router.get('/api/users', async (request) => {
  const authResponse = await requireAuth(request);
  if (authResponse) return authResponse;

  const response = await adminRoutes.getAllUsers(request);
  return new Response(response.body, {
    status: response.status,
    headers: { ...corsHeaders, ...response.headers }
  });
});

router.delete('/api/users/:id', async (request) => {
  const authResponse = await requireAuth(request);
  if (authResponse) return authResponse;

  request.params = { id: request.url.split('/').pop() };
  const response = await adminRoutes.deleteUser(request);
  return new Response(response.body, {
    status: response.status,
    headers: { ...corsHeaders, ...response.headers }
  });
});

// Get Products
router.get('/api/products', async (request) => {
  // No auth required for viewing products

  try {
    const url = new URL(request.url);
    const category = url.searchParams.get('category');
    const limit = parseInt(url.searchParams.get('limit')) || 20;
    const offset = parseInt(url.searchParams.get('offset')) || 0;

    // Validate pagination params
    if (limit < 1 || limit > 100) {
      return new Response(JSON.stringify({
        error: 'Invalid limit',
        message: 'Limit must be between 1 and 100'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

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
      products: result.results || [],
      pagination: {
        limit,
        offset,
        total: result.results.length,
        hasMore: result.results.length === limit
      }
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

// Admin Routes - Product Management
router.get('/api/products/:id', async (request) => {
  request.params = { id: request.url.split('/').pop() };
  return adminRoutes.getProduct(request);
});

router.put('/api/products/:id', async (request) => {
  const authResponse = await requireAuth(request);
  if (authResponse) return authResponse;

  request.params = { id: request.url.split('/').slice(-1)[0] };
  const response = await adminRoutes.updateProduct(request);
  return new Response(response.body, {
    status: response.status,
    headers: { ...corsHeaders, ...response.headers }
  });
});

router.delete('/api/products/:id', async (request) => {
  const authResponse = await requireAuth(request);
  if (authResponse) return authResponse;

  request.params = { id: request.url.split('/').pop() };
  const response = await adminRoutes.deleteProduct(request);
  return new Response(response.body, {
    status: response.status,
    headers: { ...corsHeaders, ...response.headers }
  });
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
      cartId: item.id,
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

    const total = items.reduce((sum, item) => sum + (item.product.price * item.quantity), 0);

    return new Response(JSON.stringify({
      items: items,
      subtotal: total,
      itemCount: items.length
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

// Add to Cart with validation
router.post('/api/cart/add', async (request) => {
  const authResponse = await requireAuth(request);
  if (authResponse) return authResponse;

  try {
    const { product_id, quantity } = await request.json();
    const userId = request.user.userId;

    // Validate input
    if (!product_id || !Number.isInteger(product_id) || product_id < 1) {
      return new Response(JSON.stringify({
        error: 'Invalid product ID'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    if (!quantity || !Number.isInteger(quantity) || quantity < 1 || quantity > 99) {
      return new Response(JSON.stringify({
        error: 'Invalid quantity',
        message: 'Quantity must be between 1 and 99'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Check stock
    const product = await request.env.DB.prepare(
      'SELECT stock_quantity, name FROM products WHERE id = ? AND is_active = 1'
    ).bind(product_id).first();

    if (!product) {
      return new Response(JSON.stringify({
        error: 'Product not found'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    if (product.stock_quantity < quantity) {
      return new Response(JSON.stringify({
        error: 'Insufficient stock',
        message: `Only ${product.stock_quantity} items available`
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Add to cart
    await request.env.DB.prepare(`
      INSERT INTO shopping_carts (user_id, product_id, quantity, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?)
      ON CONFLICT(user_id, product_id) DO UPDATE SET
        quantity = quantity + excluded.quantity,
        updated_at = excluded.updated_at
    `).bind(
      userId,
      product_id,
      quantity,
      new Date().toISOString(),
      new Date().toISOString()
    ).run();

    return new Response(JSON.stringify({
      message: 'Added to cart',
      product: {
        id: product_id,
        name: product.name,
        quantity: quantity
      }
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

// Remove from Cart
router.delete('/api/cart/:productId', async (request) => {
  const authResponse = await requireAuth(request);
  if (authResponse) return authResponse;

  try {
    const { productId } = request.params;
    const userId = request.user.userId;

    const result = await request.env.DB.prepare(
      'DELETE FROM shopping_carts WHERE user_id = ? AND product_id = ?'
    ).bind(userId, productId).run();

    if (result.changes === 0) {
      return new Response(JSON.stringify({
        error: 'Item not found in cart'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    return new Response(JSON.stringify({
      message: 'Item removed from cart'
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

// Create Booking with validation
router.post('/api/dojo/bookings', async (request) => {
  const authResponse = await requireAuth(request);
  if (authResponse) return authResponse;

  try {
    const { dojo_id, class_type, booking_date, booking_time } = await request.json();
    const userId = request.user.userId;

    // Validate input
    if (!dojo_id || !class_type || !booking_date || !booking_time) {
      return new Response(JSON.stringify({
        error: 'Missing required fields',
        message: 'All fields are required'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Validate class type
    const validClassTypes = ['beginners', 'all_levels', 'advanced', 'open_mat', 'competition'];
    if (!validClassTypes.includes(class_type)) {
      return new Response(JSON.stringify({
        error: 'Invalid class type',
        message: `Class type must be one of: ${validClassTypes.join(', ')}`
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Validate date is not in the past
    const bookingDateTime = new Date(`${booking_date}T${booking_time}`);
    if (bookingDateTime < new Date()) {
      return new Response(JSON.stringify({
        error: 'Invalid booking date',
        message: 'Cannot book classes in the past'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Check for duplicate booking
    const existingBooking = await request.env.DB.prepare(
      'SELECT id FROM bookings WHERE user_id = ? AND dojo_id = ? AND booking_date = ? AND booking_time = ? AND status != ?'
    ).bind(userId, dojo_id, booking_date, booking_time, 'cancelled').first();

    if (existingBooking) {
      return new Response(JSON.stringify({
        error: 'Duplicate booking',
        message: 'You already have a booking for this time'
      }), {
        status: 409,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

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
    const url = new URL(request.url);
    const status = url.searchParams.get('status');

    let query = `
      SELECT b.*, d.name as dojo_name
      FROM bookings b
      JOIN dojos d ON b.dojo_id = d.id
      WHERE b.user_id = ?
    `;

    const params = [userId];

    if (status) {
      query += ' AND b.status = ?';
      params.push(status);
    }

    query += ' ORDER BY b.booking_date DESC, b.booking_time DESC';

    const result = await request.env.DB.prepare(query).bind(...params).all();

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

// Cancel Booking
router.put('/api/bookings/:id/cancel', async (request) => {
  const authResponse = await requireAuth(request);
  if (authResponse) return authResponse;

  try {
    const { id } = request.params;
    const userId = request.user.userId;
    const { reason } = await request.json();

    // Check if booking exists and belongs to user
    const booking = await request.env.DB.prepare(
      'SELECT * FROM bookings WHERE id = ? AND user_id = ?'
    ).bind(id, userId).first();

    if (!booking) {
      return new Response(JSON.stringify({
        error: 'Booking not found'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    if (booking.status === 'cancelled') {
      return new Response(JSON.stringify({
        error: 'Booking already cancelled'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Cancel booking
    await request.env.DB.prepare(`
      UPDATE bookings 
      SET status = 'cancelled', 
          cancelled_at = ?, 
          cancellation_reason = ?,
          updated_at = ?
      WHERE id = ?
    `).bind(
      new Date().toISOString(),
      sanitizeInput(reason || 'User cancelled'),
      new Date().toISOString(),
      id
    ).run();

    return new Response(JSON.stringify({
      message: 'Booking cancelled successfully',
      bookingId: id
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Cancel booking error:', error);
    return new Response(JSON.stringify({
      error: 'Failed to cancel booking',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Get Videos - NOW WITH AUTHENTICATION
router.get('/api/videos', async (request) => {
  const authResponse = await requireAuth(request);
  if (authResponse) return authResponse;

  try {
    const url = new URL(request.url);
    const premium = url.searchParams.get('premium');
    const category = url.searchParams.get('category');
    const limit = parseInt(url.searchParams.get('limit')) || 20;
    const offset = parseInt(url.searchParams.get('offset')) || 0;

    let query = 'SELECT * FROM videos WHERE status = "published"';
    const params = [];

    // Check if user has premium access
    const userRole = request.user.role;
    const isPremium = userRole === 'premium' || userRole === 'admin';

    if (premium !== null) {
      query += ' AND is_premium = ?';
      params.push(premium === 'true' ? 1 : 0);
    } else if (!isPremium) {
      // Non-premium users can only see free videos
      query += ' AND is_premium = 0';
    }

    if (category) {
      query += ' AND category = ?';
      params.push(category);
    }

    query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
    params.push(limit, offset);

    const result = await request.env.DB.prepare(query).bind(...params).all();

    return new Response(JSON.stringify({
      videos: result.results || [],
      userAccess: isPremium ? 'premium' : 'free',
      pagination: {
        limit,
        offset,
        hasMore: result.results.length === limit
      }
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

// Delete Video (Admin)
router.delete('/api/videos/:id', async (request) => {
  const authResponse = await requireAuth(request);
  if (authResponse) return authResponse;

  request.params = { id: request.url.split('/').pop() };
  const response = await adminRoutes.deleteVideo(request);
  return new Response(response.body, {
    status: response.status,
    headers: { ...corsHeaders, ...response.headers }
  });
});

// Record Video View
router.post('/api/videos/:id/view', async (request) => {
  const authResponse = await requireAuth(request);
  if (authResponse) return authResponse;

  try {
    const { id } = request.params;
    const userId = request.user.userId;

    // Check if video exists
    const video = await request.env.DB.prepare(
      'SELECT * FROM videos WHERE id = ? AND status = "published"'
    ).bind(id).first();

    if (!video) {
      return new Response(JSON.stringify({
        error: 'Video not found'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Check premium access
    if (video.is_premium && request.user.role !== 'premium' && request.user.role !== 'admin') {
      return new Response(JSON.stringify({
        error: 'Premium content',
        message: 'Upgrade to premium to watch this video'
      }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Update view count
    await request.env.DB.prepare(
      'UPDATE videos SET view_count = view_count + 1 WHERE id = ?'
    ).bind(id).run();

    // Record view history (if table exists)
    try {
      await request.env.DB.prepare(`
        INSERT INTO video_views (video_id, user_id, viewed_at)
        VALUES (?, ?, ?)
      `).bind(id, userId, new Date().toISOString()).run();
    } catch (e) {
      // Table might not exist yet
    }

    return new Response(JSON.stringify({
      message: 'View recorded',
      videoId: id
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('Record view error:', error);
    return new Response(JSON.stringify({
      error: 'Failed to record view',
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

    // Validate return date
    const returnDate = new Date(return_due_date);
    if (returnDate <= new Date()) {
      return new Response(JSON.stringify({
        error: 'Invalid return date',
        message: 'Return date must be in the future'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Check availability
    const rental = await request.env.DB.prepare(
      'SELECT * FROM rentals WHERE id = ?'
    ).bind(rentalId).first();

    if (!rental) {
      return new Response(JSON.stringify({
        error: 'Rental not found'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    if (rental.available_quantity < 1) {
      return new Response(JSON.stringify({
        error: 'Rental not available',
        message: 'No items available for rent'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Create transaction
    const result = await request.env.DB.prepare(`
      INSERT INTO rental_transactions (rental_id, user_id, rental_date, return_due_date, status, created_at)
      VALUES (?, ?, ?, ?, ?, ?)
    `).bind(
      rentalId,
      user_id,
      new Date().toISOString(),
      return_due_date,
      'active',
      new Date().toISOString()
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
        status: 'active',
        rental_details: {
          item_name: rental.item_name,
          rental_price: rental.rental_price,
          deposit_amount: rental.deposit_amount
        }
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

// Payment routes with authentication
router.all('/api/orders/*', async (request) => {
  const authResponse = await requireAuth(request);
  if (authResponse) return authResponse;
  return paymentRoutes.handle(request);
});
router.all('/api/payments/*', async (request) => {
  const authResponse = await requireAuth(request);
  if (authResponse) return authResponse;
  return paymentRoutes.handle(request);
});
router.all('/api/subscriptions/*', async (request) => {
  const authResponse = await requireAuth(request);
  if (authResponse) return authResponse;
  return paymentRoutes.handle(request);
});

// Instructors admin routes
router.all('/api/instructors/*', instructorsAdminRoutes.handle);
router.get('/api/instructors', instructorsAdminRoutes.handle);
router.post('/api/instructors', instructorsAdminRoutes.handle);

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

      // Apply rate limiting
      const rateLimitResponse = await rateLimitMiddleware(request);
      if (rateLimitResponse) return rateLimitResponse;

      // Handle request
      const response = await router.handle(request);

      // Add rate limit headers to successful responses
      if (request.rateLimitInfo) {
        const newHeaders = new Headers(response.headers);
        newHeaders.set('X-RateLimit-Limit', request.rateLimitInfo.limit.toString());
        newHeaders.set('X-RateLimit-Remaining', request.rateLimitInfo.remaining.toString());
        newHeaders.set('X-RateLimit-Reset', request.rateLimitInfo.reset);

        return new Response(response.body, {
          status: response.status,
          statusText: response.statusText,
          headers: newHeaders
        });
      }

      return response;
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
