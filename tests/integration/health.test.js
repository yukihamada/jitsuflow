import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { createTestEnv } from './_helpers.js';

describe('integration: GET /api/health', () => {
  let env;

  beforeEach(async () => {
    env = await createTestEnv();
  });

  afterEach(async () => {
    await env.dispose();
  });

  it('returns healthy from the real Worker handler', async () => {
    const res = await env.fetch('/api/health');
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.status).toBe('healthy');
    expect(body.service).toBe('JitsuFlow API');
  });

  it('exposes the seeded users table for follow-up tests', async () => {
    const row = await env.db.prepare(
      'SELECT name FROM sqlite_master WHERE type=\'table\' AND name=\'users\''
    ).first();
    expect(row?.name).toBe('users');
  });
});
