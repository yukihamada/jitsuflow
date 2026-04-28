import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { createTestEnv } from './_helpers.js';

/**
 * KV-backed rate limit. Tests use a tiny limit so we don't have to
 * hammer the worker 100x.
 */
describe('integration: KV-backed rate limiting', () => {
  let env;

  beforeEach(async () => {
    env = await createTestEnv({
      bindings: {
        RATE_LIMIT_MAX: '3',
        RATE_LIMIT_WINDOW_SECONDS: '60'
      }
    });
  });

  afterEach(async () => {
    await env.dispose();
  });

  it('allows requests up to the limit and 429s the next one', async () => {
    const ip = '203.0.113.10';
    const headers = { 'CF-Connecting-IP': ip };

    for (let i = 0; i < 3; i++) {
      const ok = await env.fetch('/api/health', { headers });
      expect(ok.status).toBe(200);
    }

    const blocked = await env.fetch('/api/health', { headers });
    expect(blocked.status).toBe(429);
    expect(blocked.headers.get('Retry-After')).toBe('60');
    expect(blocked.headers.get('X-RateLimit-Limit')).toBe('3');
    expect(blocked.headers.get('X-RateLimit-Remaining')).toBe('0');
  });

  it('tracks separate IPs in separate buckets', async () => {
    for (let i = 0; i < 3; i++) {
      const r = await env.fetch('/api/health', {
        headers: { 'CF-Connecting-IP': '198.51.100.1' }
      });
      expect(r.status).toBe(200);
    }

    // A different IP should NOT be blocked yet
    const otherIp = await env.fetch('/api/health', {
      headers: { 'CF-Connecting-IP': '198.51.100.2' }
    });
    expect(otherIp.status).toBe(200);
  });

  it('emits X-RateLimit-* headers on allowed responses too', async () => {
    const res = await env.fetch('/api/health', {
      headers: { 'CF-Connecting-IP': '198.51.100.99' }
    });
    expect(res.status).toBe(200);
    expect(res.headers.get('X-RateLimit-Limit')).toBe('3');
    expect(res.headers.get('X-RateLimit-Remaining')).toBe('2');
    expect(res.headers.get('X-RateLimit-Reset')).toBeTruthy();
  });
});
