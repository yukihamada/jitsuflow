/**
 * Simplified authentication middleware for JitsuFlow API
 * Compatible with Cloudflare Workers
 */

import { corsHeaders } from './cors';
import { verifyJWT } from '../utils/crypto';

export async function authMiddleware(request) {
  // Skip auth for public endpoints
  const publicEndpoints = [
    '/api/users/register',
    '/api/users/login',
    '/api/health',
    '/api/payments/webhook'
  ];
  
  const url = new URL(request.url);
  if (publicEndpoints.some(endpoint => url.pathname.includes(endpoint))) {
    return;
  }
  
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
    
    // Verify JWT token
    const payload = await verifyJWT(token, request.env.JWT_SECRET || 'your-secret-key');
    
    // Check token expiration
    if (payload.exp && payload.exp < Math.floor(Date.now() / 1000)) {
      throw new Error('Token expired');
    }
    
    // Attach user info to request
    request.user = {
      userId: payload.userId,
      email: payload.email,
      role: payload.role || 'user'
    };
    
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

// Rate limiting middleware
export async function rateLimitMiddleware(request) {
  const ip = request.headers.get('CF-Connecting-IP') || request.headers.get('X-Forwarded-For') || 'unknown';
  const key = `ratelimit:${ip}`;
  const limit = 100; // requests per hour
  const windowMs = 60 * 60 * 1000; // 1 hour
  
  try {
    const now = Date.now();
    const windowStart = now - windowMs;
    
    // Get current count from KV
    const data = await request.env.SESSIONS.get(key, 'json');
    
    if (data && data.count && data.resetTime > now) {
      if (data.count >= limit) {
        return new Response(JSON.stringify({
          error: 'Too Many Requests',
          message: 'Rate limit exceeded'
        }), {
          status: 429,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
            'X-RateLimit-Limit': limit.toString(),
            'X-RateLimit-Remaining': '0',
            'X-RateLimit-Reset': new Date(data.resetTime).toISOString()
          }
        });
      }
      
      // Increment count
      await request.env.SESSIONS.put(key, JSON.stringify({
        count: data.count + 1,
        resetTime: data.resetTime
      }), {
        expirationTtl: Math.floor((data.resetTime - now) / 1000)
      });
      
      request.rateLimitInfo = {
        limit,
        remaining: limit - data.count - 1,
        reset: new Date(data.resetTime).toISOString()
      };
    } else {
      // First request in window
      const resetTime = now + windowMs;
      await request.env.SESSIONS.put(key, JSON.stringify({
        count: 1,
        resetTime
      }), {
        expirationTtl: Math.floor(windowMs / 1000)
      });
      
      request.rateLimitInfo = {
        limit,
        remaining: limit - 1,
        reset: new Date(resetTime).toISOString()
      };
    }
  } catch (error) {
    console.error('Rate limiting error:', error);
    // Continue without rate limiting on error
  }
}