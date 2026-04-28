import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { createTestEnv, seedUser, authedRequest } from './_helpers.js';
import { generateJWT } from '../../src/middleware/auth.js';

/**
 * Endpoints that should reject any non-admin caller. Without this guard
 * the only barrier is requireAuth, so a regular registered user could
 * mutate or read every record.
 */
const ADMIN_ENDPOINTS = [
  { method: 'GET',    path: '/api/users' },
  { method: 'DELETE', path: '/api/users/2' },
  { method: 'PUT',    path: '/api/products/1', body: { name: 'x', price: 100 } },
  { method: 'DELETE', path: '/api/products/1' },
  { method: 'DELETE', path: '/api/videos/1' }
];

const TEST_JWT_SECRET = 'test-jwt-secret';

async function tokenFor({ userId, email, role }) {
  return generateJWT({ userId, email, role }, TEST_JWT_SECRET, '1h');
}

describe('integration: admin endpoints reject non-admin tokens (403)', () => {
  let env;

  beforeEach(async () => {
    env = await createTestEnv();
    // Seed two users so that PUT/DELETE on id=2 has a target row to act on.
    await seedUser(env.db, { email: 'admin@example.com', passwordHash: 'pbkdf2$x', role: 'admin' });
    await seedUser(env.db, { email: 'user@example.com',  passwordHash: 'pbkdf2$x', role: 'user' });
  });

  afterEach(async () => {
    await env.dispose();
  });

  for (const ep of ADMIN_ENDPOINTS) {
    it(`${ep.method} ${ep.path} with a regular user token returns 403`, async () => {
      const token = await tokenFor({ userId: 2, email: 'user@example.com', role: 'user' });
      const res = await authedRequest(env.fetch, ep.method, ep.path, { token, body: ep.body });
      expect(res.status).toBe(403);
      const body = await res.json();
      expect(body.error).toBe('Forbidden');
    });
  }

  it('GET /api/users with no token returns 401 (auth still runs first)', async () => {
    const res = await env.fetch('/api/users');
    expect(res.status).toBe(401);
  });

  it('GET /api/users with an admin token does NOT return 403 (passes the role gate)', async () => {
    const token = await tokenFor({ userId: 1, email: 'admin@example.com', role: 'admin' });
    const res = await authedRequest(env.fetch, 'GET', '/api/users', { token });
    // Underlying handler may still 500 if its query doesn't match the
    // minimal test schema — what matters here is "not 403".
    expect(res.status).not.toBe(403);
    expect(res.status).not.toBe(401);
  });
});
