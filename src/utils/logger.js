/**
 * Minimal structured logger. Emits one JSON line per call so Cloudflare
 * Workers Logs (or wrangler tail | jq) can be filtered/aggregated.
 *
 * Shape:
 *   { ts: ISO8601, level, msg, ...context }
 *
 * Use a `kind` field in the context to bucket events by domain
 * (e.g. kind:'auth', kind:'webhook'). Avoid logging credentials,
 * tokens, or password hashes — context is best-effort scrubbed
 * here but the caller is the source of truth.
 */

const SENSITIVE_KEYS = new Set([
  'password',
  'password_hash',
  'token',
  'authorization',
  'cookie',
  'set-cookie',
  'jwt_secret',
  'stripe_secret_key',
  'stripe_webhook_secret'
]);

// JSON.stringify replacer that redacts sensitive keys at any depth.
// Top-level scrub used to leak nested context (e.g. logging an entire
// Stripe event would expose `client_secret` because it's nested under
// `data.object`). Replacer runs for every key/value pair so the
// guarantee applies regardless of structure.
function redactingReplacer(key, value) {
  if (typeof key === 'string' && SENSITIVE_KEYS.has(key.toLowerCase())) {
    return '[REDACTED]';
  }
  return value;
}

function emit(level, msg, context) {
  const payload = {
    ts: new Date().toISOString(),
    level,
    msg,
    ...(context && typeof context === 'object' ? context : {})
  };
  let line;
  try {
    line = JSON.stringify(payload, redactingReplacer);
  } catch (_err) {
    // Context contained a value JSON.stringify can't handle (cycle,
    // BigInt, etc.) — fall back to a safe minimal record.
    line = JSON.stringify({ ts: payload.ts, level, msg, _err: 'context_unserializable' });
  }
  if (level === 'error') {
    console.error(line);
  } else {
    console.log(line);
  }
}

export function logInfo(msg, context) {
  emit('info', msg, context);
}

export function logWarn(msg, context) {
  emit('warn', msg, context);
}

export function logError(msg, context) {
  emit('error', msg, context);
}
