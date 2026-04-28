import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { createTestEnv, seedUser, authedRequest } from './_helpers.js';

describe('integration: password hashing through register / login', () => {
  let env;

  beforeEach(async () => {
    env = await createTestEnv();
  });

  afterEach(async () => {
    await env.dispose();
  });

  async function readPasswordHash(email) {
    const row = await env.db.prepare(
      'SELECT password_hash FROM users WHERE email = ?'
    ).bind(email).first();
    return row?.password_hash;
  }

  it('stores new registrations as PBKDF2 hashes', async () => {
    const res = await authedRequest(env.fetch, 'POST', '/api/users/register', {
      body: {
        email: 'alice@example.com',
        password: 'super-secret-pw',
        name: 'Alice'
      }
    });
    expect(res.status).toBe(201);

    const stored = await readPasswordHash('alice@example.com');
    expect(stored?.startsWith('pbkdf2$100000$')).toBe(true);
  });

  it('lets a legacy btoa user log in and upgrades the hash', async () => {
    const password = 'legacy-pw-123';
    const legacyHash = btoa(password);
    const seeded = await seedUser(env.db, {
      email: 'bob@example.com',
      passwordHash: legacyHash
    });

    const before = await readPasswordHash('bob@example.com');
    expect(before).toBe(legacyHash);

    const loginRes = await authedRequest(env.fetch, 'POST', '/api/users/login', {
      body: { email: 'bob@example.com', password }
    });
    expect(loginRes.status).toBe(200);
    const body = await loginRes.json();
    expect(body.user.id).toBe(seeded.id);

    const after = await readPasswordHash('bob@example.com');
    expect(after?.startsWith('pbkdf2$100000$')).toBe(true);
    expect(after).not.toBe(legacyHash);
  });

  it('keeps accepting the same password after the upgrade', async () => {
    const password = 'second-login-pw';
    await seedUser(env.db, {
      email: 'carol@example.com',
      passwordHash: btoa(password)
    });

    const first = await authedRequest(env.fetch, 'POST', '/api/users/login', {
      body: { email: 'carol@example.com', password }
    });
    expect(first.status).toBe(200);

    const second = await authedRequest(env.fetch, 'POST', '/api/users/login', {
      body: { email: 'carol@example.com', password }
    });
    expect(second.status).toBe(200);
  });

  it('rejects a wrong password for a legacy account without upgrading', async () => {
    const realPassword = 'real-pw';
    const legacyHash = btoa(realPassword);
    await seedUser(env.db, {
      email: 'dan@example.com',
      passwordHash: legacyHash
    });

    const res = await authedRequest(env.fetch, 'POST', '/api/users/login', {
      body: { email: 'dan@example.com', password: 'wrong-pw' }
    });
    expect(res.status).toBe(401);

    const after = await readPasswordHash('dan@example.com');
    expect(after).toBe(legacyHash);
  });

  it('rejects a wrong password for a PBKDF2 account', async () => {
    await authedRequest(env.fetch, 'POST', '/api/users/register', {
      body: { email: 'eve@example.com', password: 'right-pw', name: 'Eve' }
    });

    const res = await authedRequest(env.fetch, 'POST', '/api/users/login', {
      body: { email: 'eve@example.com', password: 'wrong-pw' }
    });
    expect(res.status).toBe(401);
  });
});
