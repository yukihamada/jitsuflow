/**
 * CORS helpers driven by an env allowlist.
 *
 * The previous defaults set `Access-Control-Allow-Origin: *` everywhere,
 * which is fine for a fully public API but a CSRF foot-gun once any
 * cookie / Authorization-bearing request matters.
 *
 * Configure via env binding (set as a regular var or via wrangler secret):
 *   CORS_ALLOWED_ORIGINS = "https://jitsuflow.app,https://www.jitsuflow.app,http://localhost:3000"
 *
 * Behavior:
 *   - If the binding is missing AND env.ENVIRONMENT is anything other
 *     than "production", we fall back to "*" so local dev keeps
 *     working without ceremony. In production, missing config means
 *     no CORS header is emitted (most browsers block — fail closed).
 *   - If the binding is set, only origins whose exact string matches
 *     get reflected back. The wildcard "*" is honoured if explicitly
 *     listed.
 */

const BASE_HEADERS = {
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Requested-With',
  'Access-Control-Max-Age': '86400'
};

function parseAllowlist(env) {
  const raw = env?.CORS_ALLOWED_ORIGINS;
  if (typeof raw !== 'string' || raw.trim().length === 0) return null;
  return raw.split(',').map(s => s.trim()).filter(Boolean);
}

/**
 * Pick the value for the Access-Control-Allow-Origin header for this
 * request. Returns undefined when no header should be set.
 */
export function pickAllowedOrigin(request, env) {
  const requestOrigin = request.headers.get('Origin');
  const allowlist = parseAllowlist(env);

  if (!allowlist) {
    // No allowlist configured.
    if (env?.ENVIRONMENT === 'production') return undefined;
    return '*';
  }

  if (allowlist.includes('*')) return '*';
  if (!requestOrigin) return undefined;
  // RFC 6454: scheme/host of an origin are ASCII case-insensitive
  // (port is exact). Normalize both sides for comparison so a
  // misconfigured allowlist like "https://JitsuFlow.app" still
  // matches a browser-sent "https://jitsuflow.app". Reflect the
  // *original* request Origin in the response header to keep
  // browsers happy.
  const normalizedRequestOrigin = requestOrigin.toLowerCase();
  const matched = allowlist.some(o => o.toLowerCase() === normalizedRequestOrigin);
  return matched ? requestOrigin : undefined;
}

/**
 * Build the CORS header bag for a given request. Always includes the
 * methods/headers/max-age. Allow-Origin only included when allowed.
 */
export function buildCorsHeaders(request, env) {
  const headers = { ...BASE_HEADERS };
  const allowed = pickAllowedOrigin(request, env);
  if (allowed) {
    headers['Access-Control-Allow-Origin'] = allowed;
    if (allowed !== '*') {
      // Vary so caches don't conflate origins.
      headers['Vary'] = 'Origin';
    }
  }
  return headers;
}
