/**
 * User routes for JitsuFlow API
 * Production-ready with bcrypt and JWT
 */

import { Router } from 'itty-router';
import { corsHeaders } from '../middleware/cors';
import { generateJWT, hashPassword, verifyPassword } from '../utils/crypto';

const router = Router();

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
    
    // Hash password with Web Crypto API
    const hashedPassword = await hashPassword(password);
    
    // Create user
    const result = await request.env.DB.prepare(
      'INSERT INTO users (email, password_hash, name, phone, created_at) VALUES (?, ?, ?, ?, ?)'
    ).bind(email, hashedPassword, name, phone, new Date().toISOString()).run();
    
    // Generate JWT token
    const token = await generateJWT(
      { userId: result.meta.last_row_id, email, role: 'user' },
      request.env.JWT_SECRET,
      request.env.JWT_EXPIRES_IN || '7d'
    );
    
    return new Response(JSON.stringify({
      message: 'User created successfully',
      user: {
        id: result.meta.last_row_id,
        email,
        name
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
      'SELECT id, email, password_hash, name FROM users WHERE email = ?'
    ).bind(email).first();
    
    if (!user) {
      return new Response(JSON.stringify({
        error: 'Invalid credentials',
        message: 'Email or password is incorrect'
      }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // Verify password with Web Crypto API
    const isValidPassword = await verifyPassword(password, user.password_hash);
    
    if (!isValidPassword) {
      return new Response(JSON.stringify({
        error: 'Invalid credentials',
        message: 'Email or password is incorrect'
      }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // Generate JWT token
    const token = await generateJWT(
      { userId: user.id, email: user.email, role: user.role || 'user' },
      request.env.JWT_SECRET,
      request.env.JWT_EXPIRES_IN || '7d'
    );
    
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