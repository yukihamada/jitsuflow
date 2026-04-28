import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { createTestEnv, authedRequest } from './_helpers.js';
import { generateJWT } from '../../src/middleware/auth.js';

const TEST_JWT_SECRET = 'test-jwt-secret';

describe('integration: JWT auth on /api/users/profile (replaces self-rolled btoa token)', () => {
  let env;

  beforeEach(async () => {
    env = await createTestEnv();
  });

  afterEach(async () => {
    await env.dispose();
  });

  it('register returns a valid signed JWT (3 base64url segments)', async () => {
    const res = await authedRequest(env.fetch, 'POST', '/api/users/register', {
      body: { email: 'jwt@example.com', password: 'password123', name: 'Jay' }
    });
    expect(res.status).toBe(201);
    const body = await res.json();
    expect(body.token.split('.')).toHaveLength(3);
  });

  it('a token freshly issued by login is accepted on a protected endpoint', async () => {
    await authedRequest(env.fetch, 'POST', '/api/users/register', {
      body: { email: 'jwt2@example.com', password: 'password123', name: 'Jay' }
    });
    const loginRes = await authedRequest(env.fetch, 'POST', '/api/users/login', {
      body: { email: 'jwt2@example.com', password: 'password123' }
    });
    const { token } = await loginRes.json();

    const protectedRes = await authedRequest(env.fetch, 'PUT', '/api/users/profile', {
      token,
      body: { name: 'Renamed' }
    });
    expect(protectedRes.status).not.toBe(401);
  });

  it('rejects a tampered JWT (signature mismatch)', async () => {
    const valid = await generateJWT(
      { userId: 99, email: 'a@b.c', role: 'user' },
      TEST_JWT_SECRET,
      '1h'
    );
    const [h, p, s] = valid.split('.');
    // Flip a payload byte then keep the original signature → no longer matches
    const tamperedPayload = p.slice(0, -1) + (p.slice(-1) === 'A' ? 'B' : 'A');
    const tampered = [h, tamperedPayload, s].join('.');

    const res = await authedRequest(env.fetch, 'PUT', '/api/users/profile', {
      token: tampered,
      body: { name: 'Renamed' }
    });
    expect(res.status).toBe(401);
  });

  it('rejects a JWT signed with a different secret', async () => {
    const wrongSecretToken = await generateJWT(
      { userId: 1, email: 'a@b.c', role: 'user' },
      'some-other-secret',
      '1h'
    );
    const res = await authedRequest(env.fetch, 'PUT', '/api/users/profile', {
      token: wrongSecretToken,
      body: { name: 'Renamed' }
    });
    expect(res.status).toBe(401);
  });

  it('rejects an expired JWT', async () => {
    // generateJWT only takes positive expiresIn, so build manually with
    // an exp in the past.
    const expired = await generateJWT(
      { userId: 1, email: 'a@b.c', role: 'user' },
      TEST_JWT_SECRET,
      '1s'
    );
    // Wait long enough that floor(now/1000) is strictly greater than exp.
    // exp is calculated as floor(now)+1 so we need at least 2 full seconds.
    await new Promise(r => setTimeout(r, 2200));

    const res = await authedRequest(env.fetch, 'PUT', '/api/users/profile', {
      token: expired,
      body: { name: 'Renamed' }
    });
    expect(res.status).toBe(401);
  });

  it('rejects the legacy unsigned base64 token format', async () => {
    // Old createToken: btoa(JSON.stringify({...payload, exp: ms}))
    const legacy = btoa(JSON.stringify({
      userId: 1,
      email: 'a@b.c',
      role: 'user',
      exp: Date.now() + 3600 * 1000
    }));
    const res = await authedRequest(env.fetch, 'PUT', '/api/users/profile', {
      token: legacy,
      body: { name: 'Renamed' }
    });
    expect(res.status).toBe(401);
  });

  it('rejects a request with no Authorization header', async () => {
    const res = await env.fetch('/api/users/profile', { method: 'PUT' });
    expect(res.status).toBe(401);
  });
});

describe('integration: JWT_SECRET binding missing → 500', () => {
  // QA M11: requireAuth fails closed when JWT_SECRET is unbound
  // (introduced in PR #3). Without this dedicated env we never
  // exercise that branch because DEFAULT_BINDINGS always sets one.
  let env;

  beforeEach(async () => {
    env = await createTestEnv({ bindings: { JWT_SECRET: undefined } });
  });

  afterEach(async () => {
    await env.dispose();
  });

  it('returns 500 (server misconfiguration), not 401, when secret is unbound', async () => {
    // Token is irrelevant — the secret check happens before verify.
    const res = await authedRequest(env.fetch, 'PUT', '/api/users/profile', {
      token: 'irrelevant.token.here',
      body: { name: 'Renamed' }
    });
    expect(res.status).toBe(500);
    const body = await res.json();
    expect(body.error).toBe('Server misconfiguration');
  });
});
