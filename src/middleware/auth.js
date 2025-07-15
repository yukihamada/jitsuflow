/**
 * Authentication middleware for JitsuFlow API
 * Production-ready JWT implementation
 */

import { corsHeaders } from './cors';

// JWT verification using native crypto
export async function authMiddleware(request) {
  // Skip auth for public endpoints
  const publicEndpoints = [
    '/api/users/register',
    '/api/users/login',
    '/api/health',
    '/api/payments/webhook' // Stripe webhook
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
    const payload = await verifyJWT(token, request.env.JWT_SECRET);
    
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
    console.error('Auth error:', error);
    return new Response(JSON.stringify({
      error: 'Unauthorized',
      message: error.message || 'Invalid token'
    }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
}

// Generate JWT token
export async function generateJWT(payload, secret, expiresIn = '7d') {
  const header = {
    alg: 'HS256',
    typ: 'JWT'
  };
  
  // Convert expiresIn to seconds
  const expirationSeconds = parseExpiresIn(expiresIn);
  const now = Math.floor(Date.now() / 1000);
  
  const tokenPayload = {
    ...payload,
    iat: now,
    exp: now + expirationSeconds
  };
  
  const encodedHeader = base64urlEncode(JSON.stringify(header));
  const encodedPayload = base64urlEncode(JSON.stringify(tokenPayload));
  
  const signature = await createSignature(
    `${encodedHeader}.${encodedPayload}`,
    secret
  );
  
  return `${encodedHeader}.${encodedPayload}.${signature}`;
}

// Verify JWT token
export async function verifyJWT(token, secret) {
  const parts = token.split('.');
  if (parts.length !== 3) {
    throw new Error('Invalid token format');
  }
  
  const [encodedHeader, encodedPayload, signature] = parts;
  
  // Verify signature
  const expectedSignature = await createSignature(
    `${encodedHeader}.${encodedPayload}`,
    secret
  );
  
  if (signature !== expectedSignature) {
    throw new Error('Invalid signature');
  }
  
  // Decode payload
  const payload = JSON.parse(base64urlDecode(encodedPayload));
  return payload;
}

// Create HMAC SHA256 signature
async function createSignature(data, secret) {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );
  
  const signature = await crypto.subtle.sign(
    'HMAC',
    key,
    encoder.encode(data)
  );
  
  return base64urlEncode(new Uint8Array(signature));
}

// Base64URL encode
function base64urlEncode(data) {
  let base64;
  
  if (typeof data === 'string') {
    base64 = btoa(data);
  } else if (data instanceof Uint8Array) {
    const binaryString = Array.from(data, byte => String.fromCharCode(byte)).join('');
    base64 = btoa(binaryString);
  } else {
    throw new Error('Invalid data type for encoding');
  }
  
  return base64
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '');
}

// Base64URL decode
function base64urlDecode(data) {
  // Add padding if necessary
  const padding = '='.repeat((4 - (data.length % 4)) % 4);
  const base64 = data
    .replace(/-/g, '+')
    .replace(/_/g, '/')
    + padding;
  
  return atob(base64);
}

// Parse expiresIn string to seconds
function parseExpiresIn(expiresIn) {
  const units = {
    's': 1,
    'm': 60,
    'h': 3600,
    'd': 86400,
    'w': 604800
  };
  
  const match = expiresIn.match(/^(\d+)([smhdw])$/);
  if (!match) {
    throw new Error('Invalid expiresIn format');
  }
  
  const [, value, unit] = match;
  return parseInt(value) * units[unit];
}

// Rate limiting middleware
export async function rateLimitMiddleware(request) {
  const clientIp = request.headers.get('CF-Connecting-IP') || 
                   request.headers.get('X-Forwarded-For') || 
                   'unknown';
  
  const rateLimitKey = `rate_limit:${clientIp}`;
  const windowSeconds = parseInt(request.env.RATE_LIMIT_WINDOW || '60');
  const maxRequests = parseInt(request.env.RATE_LIMIT_REQUESTS || '100');
  
  try {
    // Get current request count from KV
    const currentCount = await request.env.SESSIONS.get(rateLimitKey);
    const count = currentCount ? parseInt(currentCount) : 0;
    
    if (count >= maxRequests) {
      return new Response(JSON.stringify({
        error: 'Too Many Requests',
        message: `Rate limit exceeded. Max ${maxRequests} requests per ${windowSeconds} seconds.`,
        retryAfter: windowSeconds
      }), {
        status: 429,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
          'X-RateLimit-Limit': maxRequests.toString(),
          'X-RateLimit-Remaining': '0',
          'X-RateLimit-Reset': new Date(Date.now() + windowSeconds * 1000).toISOString(),
          'Retry-After': windowSeconds.toString()
        }
      });
    }
    
    // Increment request count
    await request.env.SESSIONS.put(
      rateLimitKey,
      (count + 1).toString(),
      { expirationTtl: windowSeconds }
    );
    
    // Add rate limit headers to request for later use
    request.rateLimitInfo = {
      limit: maxRequests,
      remaining: maxRequests - count - 1,
      reset: new Date(Date.now() + windowSeconds * 1000).toISOString()
    };
    
  } catch (error) {
    console.error('Rate limit error:', error);
    // Continue without rate limiting if KV fails
  }
}

// Admin authorization middleware
export function requireAdmin(request) {
  if (!request.user || request.user.role !== 'admin') {
    return new Response(JSON.stringify({
      error: 'Forbidden',
      message: 'Admin access required'
    }), {
      status: 403,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  return null; // No error, continue
}