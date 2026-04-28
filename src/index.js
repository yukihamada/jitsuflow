/**
 * JitsuFlow Cloudflare Workers API - Enhanced Implementation
 * Fixed authentication, validation, and added security features
 */

import { Router } from 'itty-router';
import { paymentRoutes } from './routes/stripe_payments.js';
import * as adminRoutes from './routes/admin.js';
import { instructorsAdminRoutes } from './routes/instructors-admin.js';
import { hashPassword, verifyPassword, isLegacyHash } from './utils/password.js';
import { generateJWT, verifyJWT } from './middleware/auth.js';
import { pickAllowedOrigin } from './utils/cors.js';
import { logError } from './utils/logger.js';

const router = Router();

// CORS headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Requested-With',
  'Access-Control-Max-Age': '86400'
};

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

// Rate limiting middleware backed by KV (SESSIONS namespace).
// The previous in-memory Map reset on every isolate reload and was
// not shared across the global edge — effectively a no-op at scale.
//
// Limits are configurable per environment:
//   RATE_LIMIT_MAX             default 100
//   RATE_LIMIT_WINDOW_SECONDS  default 60
async function rateLimitMiddleware(request) {
  if (!request.env?.SESSIONS) {
    // No KV bound (e.g. some tests). Skip silently.
    return;
  }

  // Cloudflare always sets CF-Connecting-IP for traffic that reaches
  // a Worker (it's set by the edge before the script runs and cannot
  // be spoofed by the caller). X-Forwarded-For, in contrast, is just
  // a request header and can be set to anything by an attacker hitting
  // the workers.dev URL directly — using it as a fallback would let
  // them rotate IPs and bypass the rate limit. Don't fall back.
  const clientIp = request.headers.get('CF-Connecting-IP') || 'unknown';

  const windowSec = parseInt(request.env.RATE_LIMIT_WINDOW_SECONDS || '60', 10);
  const maxRequests = parseInt(request.env.RATE_LIMIT_MAX || '100', 10);
  const bucket = Math.floor(Date.now() / (windowSec * 1000));
  const key = `rl:${clientIp}:${bucket}`;
  const resetIso = new Date((bucket + 1) * windowSec * 1000).toISOString();

  let count = 0;
  try {
    const raw = await request.env.SESSIONS.get(key);
    if (raw) {
      const parsed = parseInt(raw, 10);
      if (!Number.isNaN(parsed)) count = parsed;
    }
  } catch (err) {
    logError('rate_limit.kv_read_failed', { kind: 'rate_limit', err: err.message });
    return; // fail open — better to serve than to wedge on KV outage
  }

  if (count >= maxRequests) {
    return new Response(JSON.stringify({
      error: 'Too Many Requests',
      message: `Rate limit exceeded. Max ${maxRequests} requests per ${windowSec} seconds.`,
      retryAfter: windowSec
    }), {
      status: 429,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json',
        'X-RateLimit-Limit': maxRequests.toString(),
        'X-RateLimit-Remaining': '0',
        'X-RateLimit-Reset': resetIso,
        'Retry-After': windowSec.toString()
      }
    });
  }

  try {
    await request.env.SESSIONS.put(key, (count + 1).toString(), {
      expirationTtl: Math.max(windowSec, 60) // KV minimum TTL is 60s
    });
  } catch (err) {
    logError('rate_limit.kv_write_failed', { kind: 'rate_limit', err: err.message });
  }

  request.rateLimitInfo = {
    limit: maxRequests,
    remaining: maxRequests - count - 1,
    reset: resetIso
  };
}

// Role middleware. Call AFTER requireAuth — relies on request.user.
// Returns a 403 Response if the role does not match, undefined otherwise.
function requireRole(request, role) {
  if (request.user?.role !== role) {
    return new Response(JSON.stringify({
      error: 'Forbidden',
      message: `Requires ${role} role`
    }), {
      status: 403,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
}

// Auth middleware. Verifies a HS256 JWT against env.JWT_SECRET and
// attaches the decoded payload to request.user.
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

  if (!request.env?.JWT_SECRET) {
    logError('auth.jwt_secret_missing', { kind: 'auth' });
    return new Response(JSON.stringify({
      error: 'Server misconfiguration',
      message: 'Auth secret not configured'
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }

  try {
    const token = authHeader.substring(7);
    const payload = await verifyJWT(token, request.env.JWT_SECRET);
    if (payload.exp && payload.exp < Math.floor(Date.now() / 1000)) {
      throw new Error('Token expired');
    }
    request.user = {
      userId: payload.userId,
      email: payload.email,
      role: payload.role || 'user'
    };
  } catch (error) {
    return new Response(JSON.stringify({
      error: 'Unauthorized',
      message: error.message || 'Invalid token'
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
    const hashedPassword = await hashPassword(password);
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
    const token = await generateJWT(
      { userId, email: sanitizedEmail, role: 'user' },
      request.env.JWT_SECRET,
      '24h'
    );

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
    logError('auth.registration_failed', { kind: 'auth', err: error.message });
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

    const verification = user
      ? await verifyPassword(password, user.password_hash)
      : { ok: false, legacy: false };

    if (!user || !verification.ok) {
      return new Response(JSON.stringify({
        error: 'Invalid credentials',
        message: 'Email or password is incorrect'
      }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Lazy migration: upgrade legacy btoa hashes on successful login.
    // CAS on the old value so concurrent legacy logins don't both
    // rewrite the row — only the first wins, the second's UPDATE
    // becomes a no-op (no rows match the now-pbkdf2 hash). Either
    // outcome leaves the row in a valid state.
    if (isLegacyHash(user.password_hash)) {
      try {
        const upgraded = await hashPassword(password);
        await request.env.DB.prepare(
          'UPDATE users SET password_hash = ?, updated_at = ? WHERE id = ? AND password_hash = ?'
        ).bind(upgraded, new Date().toISOString(), user.id, user.password_hash).run();
      } catch (err) {
        logError('auth.password_rehash_failed', { kind: 'auth', userId: user.id, err: err.message });
      }
    }

    const token = await generateJWT(
      { userId: user.id, email: user.email, role: user.role || 'user' },
      request.env.JWT_SECRET,
      '24h'
    );

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
    logError('auth.login_failed', { kind: 'auth', err: error.message });
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
  const roleResponse = requireRole(request, 'admin');
  if (roleResponse) return roleResponse;

  const response = await adminRoutes.getAllUsers(request);
  return new Response(response.body, {
    status: response.status,
    headers: { ...corsHeaders, ...response.headers }
  });
});

router.delete('/api/users/:id', async (request) => {
  const authResponse = await requireAuth(request);
  if (authResponse) return authResponse;
  const roleResponse = requireRole(request, 'admin');
  if (roleResponse) return roleResponse;

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
  const roleResponse = requireRole(request, 'admin');
  if (roleResponse) return roleResponse;

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
  const roleResponse = requireRole(request, 'admin');
  if (roleResponse) return roleResponse;

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
  const roleResponse = requireRole(request, 'admin');
  if (roleResponse) return roleResponse;

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
  // The Stripe webhook authenticates via signature (handled inside the
  // route), not via our Bearer token. Bypass requireAuth so Stripe can
  // actually deliver events.
  const url = new URL(request.url);
  if (url.pathname === '/api/payments/webhook') {
    return paymentRoutes.handle(request);
  }
  const authResponse = await requireAuth(request);
  if (authResponse) return authResponse;
  return paymentRoutes.handle(request);
});
router.all('/api/subscriptions/*', async (request) => {
  const authResponse = await requireAuth(request);
  if (authResponse) return authResponse;
  return paymentRoutes.handle(request);
});

// Instructors routes.
//
// Public reads: GET list/detail/dojos
// Admin mutations: everything else (POST/PUT/DELETE), gated by
// requireAuth + requireRole('admin') at the mount layer so a request
// without a token gets 401 (not 403, which is what would happen if
// only the inner requireAdmin in instructors-admin.js ran).
router.get('/api/instructors', instructorsAdminRoutes.handle);
router.get('/api/instructors/:id', instructorsAdminRoutes.handle);
router.get('/api/instructors/:id/dojos', instructorsAdminRoutes.handle);

const guardedInstructors = async (request) => {
  const authResponse = await requireAuth(request);
  if (authResponse) return authResponse;
  const roleResponse = requireRole(request, 'admin');
  if (roleResponse) return roleResponse;
  return instructorsAdminRoutes.handle(request);
};
router.post('/api/instructors', guardedInstructors);
router.put('/api/instructors/:id', guardedInstructors);
router.delete('/api/instructors/:id', guardedInstructors);
router.post('/api/instructors/:id/dojos', guardedInstructors);
router.delete('/api/instructors/:id/dojos/:dojoId', guardedInstructors);

// 404 handler
router.all('*', () => new Response('Not Found', {
  status: 404,
  headers: corsHeaders
}));

function applyResponseHeaders(response, request) {
  const newHeaders = new Headers(response.headers);

  // CORS allowlist (replaces the static '*' baked into corsHeaders)
  newHeaders.delete('Access-Control-Allow-Origin');
  newHeaders.delete('Vary');
  const allowedOrigin = pickAllowedOrigin(request, request.env);
  if (allowedOrigin) {
    newHeaders.set('Access-Control-Allow-Origin', allowedOrigin);
    if (allowedOrigin !== '*') newHeaders.set('Vary', 'Origin');
  }

  // Rate-limit headers when middleware annotated the request
  if (request.rateLimitInfo) {
    newHeaders.set('X-RateLimit-Limit', request.rateLimitInfo.limit.toString());
    newHeaders.set('X-RateLimit-Remaining', request.rateLimitInfo.remaining.toString());
    newHeaders.set('X-RateLimit-Reset', request.rateLimitInfo.reset);
  }

  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers: newHeaders
  });
}

export default {
  async fetch(request, env, ctx) {
    try {
      request.env = env;
      request.ctx = ctx;

      // Apply rate limiting
      const rateLimitResponse = await rateLimitMiddleware(request);
      if (rateLimitResponse) return applyResponseHeaders(rateLimitResponse, request);

      // Handle request
      const response = await router.handle(request);
      return applyResponseHeaders(response, request);
    } catch (error) {
      logError('worker.unhandled', { err: error.message, stack: error.stack });
      const errorRes = new Response(JSON.stringify({
        error: 'Internal Server Error',
        message: error.message
      }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
      return applyResponseHeaders(errorRes, request);
    }
  }
};
