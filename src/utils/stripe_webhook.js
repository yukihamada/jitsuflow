/**
 * Stripe webhook signature verification.
 *
 * Implements the v1 scheme described at
 * https://stripe.com/docs/webhooks/signatures using Web Crypto so it
 * runs inside Cloudflare Workers without the official `stripe` SDK.
 */

const DEFAULT_TOLERANCE_SECONDS = 300;

function parseSignatureHeader(header) {
  const parts = {};
  for (const segment of header.split(',')) {
    const eq = segment.indexOf('=');
    if (eq === -1) continue;
    const key = segment.slice(0, eq).trim();
    const value = segment.slice(eq + 1).trim();
    if (!key) continue;
    if (key === 'v1') {
      if (!parts.v1) parts.v1 = [];
      parts.v1.push(value);
    } else {
      parts[key] = value;
    }
  }
  return parts;
}

function hexToBytes(hex) {
  if (hex.length % 2 !== 0) return null;
  const bytes = new Uint8Array(hex.length / 2);
  for (let i = 0; i < bytes.length; i++) {
    const byte = parseInt(hex.substr(i * 2, 2), 16);
    if (Number.isNaN(byte)) return null;
    bytes[i] = byte;
  }
  return bytes;
}

function timingSafeEqual(a, b) {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff === 0;
}

async function computeHmacHex(secret, payload) {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );
  const signature = await crypto.subtle.sign('HMAC', key, encoder.encode(payload));
  return Array.from(new Uint8Array(signature))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');
}

/**
 * Verify a Stripe webhook signature and return the parsed event payload.
 *
 * @param {string} rawBody - Raw request body as received (must not be re-stringified).
 * @param {string|null} signatureHeader - Value of the `Stripe-Signature` header.
 * @param {string} secret - The endpoint signing secret (`whsec_...`).
 * @param {object} [options]
 * @param {number} [options.toleranceSeconds=300] - Maximum allowed clock skew.
 * @param {number} [options.nowSeconds] - Override current time (used in tests).
 * @returns {Promise<object>} Parsed Stripe event.
 * @throws {Error} If the signature is missing, malformed, expired, or invalid.
 */
export async function verifyStripeSignature(rawBody, signatureHeader, secret, options = {}) {
  if (!secret) {
    throw new Error('Webhook secret is not configured');
  }
  if (!signatureHeader) {
    throw new Error('Missing Stripe-Signature header');
  }

  const parsed = parseSignatureHeader(signatureHeader);
  if (!parsed.t || !parsed.v1 || parsed.v1.length === 0) {
    throw new Error('Malformed Stripe-Signature header');
  }

  const timestamp = parseInt(parsed.t, 10);
  if (Number.isNaN(timestamp)) {
    throw new Error('Malformed Stripe-Signature timestamp');
  }

  const tolerance = options.toleranceSeconds ?? DEFAULT_TOLERANCE_SECONDS;
  const now = options.nowSeconds ?? Math.floor(Date.now() / 1000);
  if (Math.abs(now - timestamp) > tolerance) {
    throw new Error('Stripe-Signature timestamp outside tolerance');
  }

  const expectedHex = await computeHmacHex(secret, `${timestamp}.${rawBody}`);
  const expectedBytes = hexToBytes(expectedHex);

  const matched = parsed.v1.some(candidate => {
    const candidateBytes = hexToBytes(candidate);
    return candidateBytes && timingSafeEqual(expectedBytes, candidateBytes);
  });

  if (!matched) {
    throw new Error('Stripe-Signature does not match expected value');
  }

  try {
    return JSON.parse(rawBody);
  } catch (_err) {
    throw new Error('Webhook payload is not valid JSON');
  }
}
