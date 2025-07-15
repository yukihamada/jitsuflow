/**
 * Crypto utilities for Cloudflare Workers
 * Simple implementations that work in Workers environment
 */

// Base64 URL encoding helper
function base64UrlEncode(str) {
  return btoa(str)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '');
}

// Base64 URL decoding helper
function base64UrlDecode(str) {
  str += '=='.slice(0, (4 - str.length % 4) % 4);
  return atob(str.replace(/-/g, '+').replace(/_/g, '/'));
}

// Simple JWT implementation for Cloudflare Workers
export async function generateJWT(payload, secret = 'your-secret-key') {
  const header = {
    alg: 'HS256',
    typ: 'JWT'
  };

  const now = Math.floor(Date.now() / 1000);
  const fullPayload = {
    ...payload,
    iat: now,
    exp: now + (24 * 60 * 60) // 24 hours
  };

  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedPayload = base64UrlEncode(JSON.stringify(fullPayload));

  const message = `${encodedHeader}.${encodedPayload}`;

  // Create HMAC signature
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
    encoder.encode(message)
  );

  const encodedSignature = base64UrlEncode(String.fromCharCode(...new Uint8Array(signature)));

  return `${message}.${encodedSignature}`;
}

export async function verifyJWT(token, secret = 'your-secret-key') {
  try {
    const [header, payload, signature] = token.split('.');

    if (!header || !payload || !signature) {
      throw new Error('Invalid token format');
    }

    // Verify signature
    const message = `${header}.${payload}`;
    const encoder = new TextEncoder();
    const key = await crypto.subtle.importKey(
      'raw',
      encoder.encode(secret),
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['verify']
    );

    const signatureBuffer = new Uint8Array(
      base64UrlDecode(signature).split('').map(c => c.charCodeAt(0))
    );

    const isValid = await crypto.subtle.verify(
      'HMAC',
      key,
      signatureBuffer,
      encoder.encode(message)
    );

    if (!isValid) {
      throw new Error('Invalid signature');
    }

    // Decode payload
    const decodedPayload = JSON.parse(base64UrlDecode(payload));

    // Check expiration
    if (decodedPayload.exp && decodedPayload.exp < Math.floor(Date.now() / 1000)) {
      throw new Error('Token expired');
    }

    return decodedPayload;
  } catch (error) {
    throw new Error('Invalid token: ' + error.message);
  }
}

// Password hashing using Web Crypto API (Cloudflare Workers compatible)
export async function hashPassword(password, salt) {
  const encoder = new TextEncoder();
  const data = encoder.encode(password + (salt || 'jitsuflow-salt'));
  const hash = await crypto.subtle.digest('SHA-256', data);
  return Array.from(new Uint8Array(hash))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');
}

// Password verification
export async function verifyPassword(password, hashedPassword, salt) {
  const hash = await hashPassword(password, salt);
  return hash === hashedPassword;
}
