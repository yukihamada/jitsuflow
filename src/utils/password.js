/**
 * Password hashing using PBKDF2-SHA256 via Web Crypto, with a
 * versioned hash format that lets us tell new hashes from legacy
 * Base64 ones written by the previous implementation:
 *
 *   pbkdf2$<iterations>$<salt_b64>$<hash_b64>
 *
 * Why PBKDF2 and not bcrypt/argon2: the Cloudflare Workers runtime
 * exposes Web Crypto natively, so PBKDF2 needs no WASM bundle. 100k
 * iterations of SHA-256 is OWASP's current minimum for PBKDF2.
 *
 * Legacy verification: any stored hash that does NOT start with
 * `pbkdf2$` is treated as the old `btoa(password)` format and
 * compared with constant-time equality.
 */

const PBKDF2_ITERATIONS = 100_000;
const PBKDF2_SALT_BYTES = 16;
const PBKDF2_HASH_BYTES = 32;
const PBKDF2_PREFIX = 'pbkdf2$';

function bytesToBase64(bytes) {
  let bin = '';
  for (let i = 0; i < bytes.length; i++) bin += String.fromCharCode(bytes[i]);
  return btoa(bin);
}

function base64ToBytes(b64) {
  const bin = atob(b64);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return bytes;
}

function timingSafeEqual(a, b) {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a[i] ^ b[i];
  return diff === 0;
}

async function pbkdf2(password, saltBytes, iterations) {
  const encoder = new TextEncoder();
  const keyMaterial = await crypto.subtle.importKey(
    'raw',
    encoder.encode(password),
    'PBKDF2',
    false,
    ['deriveBits']
  );
  const bits = await crypto.subtle.deriveBits(
    { name: 'PBKDF2', salt: saltBytes, iterations, hash: 'SHA-256' },
    keyMaterial,
    PBKDF2_HASH_BYTES * 8
  );
  return new Uint8Array(bits);
}

/**
 * Produce a fresh hash for `password` in the current scheme.
 * @param {string} password
 * @returns {Promise<string>} versioned hash string
 */
export async function hashPassword(password) {
  const salt = crypto.getRandomValues(new Uint8Array(PBKDF2_SALT_BYTES));
  const hash = await pbkdf2(password, salt, PBKDF2_ITERATIONS);
  return `${PBKDF2_PREFIX}${PBKDF2_ITERATIONS}$${bytesToBase64(salt)}$${bytesToBase64(hash)}`;
}

/**
 * Verify `password` against a stored hash. Accepts both the new
 * `pbkdf2$...` format and the legacy `btoa(password)` format.
 *
 * @param {string} password
 * @param {string} stored
 * @returns {Promise<{ok: boolean, legacy: boolean}>}
 *   `legacy` is true when the stored value is the old btoa hash and
 *   the caller should re-hash and persist.
 */
export async function verifyPassword(password, stored) {
  if (typeof stored !== 'string' || stored.length === 0) {
    return { ok: false, legacy: false };
  }

  if (stored.startsWith(PBKDF2_PREFIX)) {
    const parts = stored.slice(PBKDF2_PREFIX.length).split('$');
    if (parts.length !== 3) return { ok: false, legacy: false };
    const [iterStr, saltB64, hashB64] = parts;
    const iterations = parseInt(iterStr, 10);
    if (!Number.isFinite(iterations) || iterations <= 0) {
      return { ok: false, legacy: false };
    }
    let saltBytes;
    let expected;
    try {
      saltBytes = base64ToBytes(saltB64);
      expected = base64ToBytes(hashB64);
    } catch (_err) {
      return { ok: false, legacy: false };
    }
    const derived = await pbkdf2(password, saltBytes, iterations);
    return { ok: timingSafeEqual(derived, expected), legacy: false };
  }

  // Legacy: btoa(password)
  let encodedAttempt;
  try {
    encodedAttempt = btoa(password);
  } catch (_err) {
    return { ok: false, legacy: false };
  }
  const a = new TextEncoder().encode(encodedAttempt);
  const b = new TextEncoder().encode(stored);
  return { ok: timingSafeEqual(a, b), legacy: true };
}

/**
 * True if `stored` is in the legacy format (and should be upgraded
 * after a successful verify).
 */
export function isLegacyHash(stored) {
  return typeof stored === 'string' && stored.length > 0 && !stored.startsWith(PBKDF2_PREFIX);
}
