/**
 * Test user routes with minimal dependencies
 */

import { Router } from 'itty-router';
import { corsHeaders } from '../middleware/cors';

const router = Router();

// Ultra simple JWT for testing
function createSimpleToken(payload) {
  const data = JSON.stringify({
    ...payload,
    exp: Date.now() + 86400000 // 24 hours
  });
  return btoa(data);
}

// Test registration endpoint
router.post('/api/users/register', async (request) => {
  try {
    const body = await request.json();
    const { email, password, name, phone } = body;
    
    // Validate
    if (!email || !password || !name) {
      return new Response(JSON.stringify({
        error: 'Missing required fields'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // Check if user exists
    const existing = await request.env.DB.prepare(
      'SELECT id FROM users WHERE email = ?'
    ).bind(email).first();
    
    if (existing) {
      return new Response(JSON.stringify({
        error: 'User already exists'
      }), {
        status: 409,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // Create user with simple password storage (NOT for production!)
    const result = await request.env.DB.prepare(
      'INSERT INTO users (email, password_hash, name, phone, role, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)'
    ).bind(
      email,
      password, // Storing plain password for testing only!
      name,
      phone || null,
      'user',
      new Date().toISOString(),
      new Date().toISOString()
    ).run();
    
    const userId = result.meta.last_row_id;
    const token = createSimpleToken({ userId, email });
    
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
      message: error.message,
      stack: error.stack
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Test login endpoint
router.post('/api/users/login', async (request) => {
  try {
    const { email, password } = await request.json();
    
    if (!email || !password) {
      return new Response(JSON.stringify({
        error: 'Missing credentials'
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    const user = await request.env.DB.prepare(
      'SELECT * FROM users WHERE email = ?'
    ).bind(email).first();
    
    if (!user || user.password_hash !== password) {
      return new Response(JSON.stringify({
        error: 'Invalid credentials'
      }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    const token = createSimpleToken({ userId: user.id, email: user.email });
    
    return new Response(JSON.stringify({
      message: 'Login successful',
      user: {
        id: user.id,
        email: user.email,
        name: user.name
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

export { router as userRoutes };