/**
 * Simplified user routes for JitsuFlow API
 * Without bcrypt for Cloudflare Workers compatibility
 */

import { Router } from 'itty-router';
import { corsHeaders } from '../middleware/cors';
import { generateJWT } from '../utils/crypto';

const router = Router();

// Simple hash function for demo (replace with proper auth in production)
function simpleHash(password) {
  let hash = 0;
  for (let i = 0; i < password.length; i++) {
    const char = password.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash;
  }
  return Math.abs(hash).toString(36);
}

// User registration
router.post('/api/users/register', async (request) => {
  try {
    const { email, password, name, phone } = await request.json();
    
    // Validate input
    if (!email || !password || !name) {
      return new Response(JSON.stringify({
        error: 'Missing required fields',
        message: 'Email, password, and name are required'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // Check if user already exists
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
    
    // Simple hash for demo
    const hashedPassword = simpleHash(password);
    
    // Create user
    const result = await request.env.DB.prepare(
      'INSERT INTO users (email, password_hash, name, phone, role, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)'
    ).bind(email, hashedPassword, name, phone || null, 'user', new Date().toISOString(), new Date().toISOString()).run();
    
    const userId = result.meta.last_row_id;
    
    // Generate JWT token
    const token = await generateJWT(
      { userId, email, role: 'user' },
      request.env.JWT_SECRET || 'your-secret-key'
    );
    
    return new Response(JSON.stringify({
      message: 'Registration successful',
      user: {
        id: userId,
        email,
        name,
        phone,
        stripeCustomerId: null,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      },
      token
    }), {
      status: 201,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Registration error:', error);
    
    return new Response(JSON.stringify({
      error: 'Internal Server Error',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// User login
router.post('/api/users/login', async (request) => {
  try {
    const { email, password } = await request.json();
    
    // Validate input
    if (!email || !password) {
      return new Response(JSON.stringify({
        error: 'Missing credentials',
        message: 'Email and password are required'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // Find user
    const user = await request.env.DB.prepare(
      'SELECT * FROM users WHERE email = ?'
    ).bind(email).first();
    
    if (!user) {
      return new Response(JSON.stringify({
        error: 'Invalid credentials',
        message: 'User not found'
      }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // Verify password (simple hash for demo)
    const hashedPassword = simpleHash(password);
    if (hashedPassword !== user.password_hash) {
      return new Response(JSON.stringify({
        error: 'Invalid credentials',
        message: 'Incorrect password'
      }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // Generate JWT token
    const token = await generateJWT(
      { userId: user.id, email: user.email, role: user.role || 'user' },
      request.env.JWT_SECRET || 'your-secret-key'
    );
    
    return new Response(JSON.stringify({
      message: 'Login successful',
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        phone: user.phone,
        stripeCustomerId: user.stripe_customer_id,
        createdAt: user.created_at,
        updatedAt: user.updated_at
      },
      token
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Login error:', error);
    
    return new Response(JSON.stringify({
      error: 'Internal Server Error',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Get user profile
router.get('/api/users/profile', async (request) => {
  try {
    const userId = request.user.userId;
    
    const user = await request.env.DB.prepare(
      'SELECT id, email, name, phone, stripe_customer_id, created_at, updated_at FROM users WHERE id = ?'
    ).bind(userId).first();
    
    if (!user) {
      return new Response(JSON.stringify({
        error: 'User not found'
      }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    return new Response(JSON.stringify({
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        phone: user.phone,
        stripeCustomerId: user.stripe_customer_id,
        createdAt: user.created_at,
        updatedAt: user.updated_at
      }
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Get profile error:', error);
    
    return new Response(JSON.stringify({
      error: 'Failed to get user profile',
      message: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Update user profile
router.patch('/api/users/profile', async (request) => {
  try {
    const userId = request.user.userId;
    const { name, phone } = await request.json();
    
    const updateFields = [];
    const updateValues = [];
    
    if (name !== undefined) {
      updateFields.push('name = ?');
      updateValues.push(name);
    }
    
    if (phone !== undefined) {
      updateFields.push('phone = ?');
      updateValues.push(phone);
    }
    
    if (updateFields.length === 0) {
      return new Response(JSON.stringify({
        error: 'No fields to update'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    updateFields.push('updated_at = ?');
    updateValues.push(new Date().toISOString());
    updateValues.push(userId);
    
    await request.env.DB.prepare(
      `UPDATE users SET ${updateFields.join(', ')} WHERE id = ?`
    ).bind(...updateValues).run();
    
    return new Response(JSON.stringify({
      message: 'Profile updated successfully'
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

export { router as userRoutes };