import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { createTestEnv } from './_helpers.js';

describe('integration: CORS allowlist', () => {
  describe('with CORS_ALLOWED_ORIGINS configured', () => {
    let env;

    beforeEach(async () => {
      env = await createTestEnv({
        bindings: {
          ENVIRONMENT: 'production',
          CORS_ALLOWED_ORIGINS: 'https://jitsuflow.app,https://www.jitsuflow.app'
        }
      });
    });

    afterEach(async () => {
      await env.dispose();
    });

    it('reflects an allowlisted origin and adds Vary: Origin', async () => {
      const res = await env.fetch('/api/health', {
        headers: { Origin: 'https://jitsuflow.app' }
      });
      expect(res.headers.get('Access-Control-Allow-Origin')).toBe('https://jitsuflow.app');
      expect(res.headers.get('Vary')).toBe('Origin');
    });

    it('omits the header when the Origin is not on the allowlist', async () => {
      const res = await env.fetch('/api/health', {
        headers: { Origin: 'https://evil.example.com' }
      });
      expect(res.headers.get('Access-Control-Allow-Origin')).toBeNull();
    });

    it('omits the header when there is no Origin header', async () => {
      const res = await env.fetch('/api/health');
      expect(res.headers.get('Access-Control-Allow-Origin')).toBeNull();
    });
  });

  describe('without CORS_ALLOWED_ORIGINS in production', () => {
    let env;

    beforeEach(async () => {
      env = await createTestEnv({
        bindings: { ENVIRONMENT: 'production', CORS_ALLOWED_ORIGINS: undefined }
      });
    });

    afterEach(async () => {
      await env.dispose();
    });

    it('fails closed: no Allow-Origin header at all', async () => {
      const res = await env.fetch('/api/health', {
        headers: { Origin: 'https://anything.example.com' }
      });
      expect(res.headers.get('Access-Control-Allow-Origin')).toBeNull();
    });
  });

  describe('without CORS_ALLOWED_ORIGINS in non-production (dev convenience)', () => {
    let env;

    beforeEach(async () => {
      env = await createTestEnv({
        bindings: { ENVIRONMENT: 'test', CORS_ALLOWED_ORIGINS: undefined }
      });
    });

    afterEach(async () => {
      await env.dispose();
    });

    it('falls back to wildcard so local dev keeps working', async () => {
      const res = await env.fetch('/api/health', {
        headers: { Origin: 'http://localhost:3000' }
      });
      expect(res.headers.get('Access-Control-Allow-Origin')).toBe('*');
    });
  });
});
