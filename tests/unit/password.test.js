import { describe, it, expect } from 'vitest';
import { hashPassword, verifyPassword, isLegacyHash } from '../../src/utils/password.js';

describe('password.hashPassword', () => {
  it('produces a versioned PBKDF2 hash', async () => {
    const stored = await hashPassword('correct horse battery staple');
    expect(stored.startsWith('pbkdf2$600000$')).toBe(true);
    const parts = stored.split('$');
    expect(parts).toHaveLength(4);
    expect(parts[0]).toBe('pbkdf2');
    expect(parts[1]).toBe('600000');
    expect(parts[2].length).toBeGreaterThan(0);
    expect(parts[3].length).toBeGreaterThan(0);
  });

  it('uses a fresh salt each call (no two hashes match)', async () => {
    const a = await hashPassword('same-password');
    const b = await hashPassword('same-password');
    expect(a).not.toBe(b);
  });
});

describe('password.verifyPassword (PBKDF2 path)', () => {
  it('verifies a correct password', async () => {
    const stored = await hashPassword('s3cret-pw');
    const result = await verifyPassword('s3cret-pw', stored);
    expect(result).toEqual({ ok: true, legacy: false });
  });

  it('rejects a wrong password', async () => {
    const stored = await hashPassword('s3cret-pw');
    const result = await verifyPassword('wrong-pw', stored);
    expect(result).toEqual({ ok: false, legacy: false });
  });

  it('rejects a malformed pbkdf2 string', async () => {
    expect(await verifyPassword('x', 'pbkdf2$nope')).toEqual({ ok: false, legacy: false });
    expect(await verifyPassword('x', 'pbkdf2$100000$bad$bad')).toEqual({ ok: false, legacy: false });
  });

  it('rejects an empty stored hash', async () => {
    expect(await verifyPassword('x', '')).toEqual({ ok: false, legacy: false });
  });

  it('does not throw on garbage stored values (returns ok:false)', async () => {
    // QA M4: Web Crypto / base64 decoders can throw on weird inputs.
    // The verifier must absorb those and return a clean rejection so
    // /login returns 401 not 500 (sidechannel).
    const cases = [
      'pbkdf2$100000$$$$extra',                 // malformed delimiter shape
      'pbkdf2$abc$saltB64$hashB64',             // non-numeric iterations
      'pbkdf2$100000$@@@invalid_b64@@@$abc==',  // un-decodable base64
      null,
      undefined,
      42,
      {}
    ];
    for (const stored of cases) {
      const result = await verifyPassword('any-pw', stored);
      expect(result.ok).toBe(false);
    }
  });
});

describe('password.verifyPassword (legacy btoa path)', () => {
  it('accepts the matching legacy hash and flags it', async () => {
    const legacy = btoa('legacy-pw');
    const result = await verifyPassword('legacy-pw', legacy);
    expect(result).toEqual({ ok: true, legacy: true });
  });

  it('rejects a wrong password against a legacy hash', async () => {
    const legacy = btoa('legacy-pw');
    const result = await verifyPassword('different', legacy);
    expect(result).toEqual({ ok: false, legacy: true });
  });
});

describe('password.isLegacyHash', () => {
  it('returns true for legacy btoa hashes', () => {
    expect(isLegacyHash(btoa('foo'))).toBe(true);
  });

  it('returns false for the new pbkdf2 format', async () => {
    const stored = await hashPassword('foo');
    expect(isLegacyHash(stored)).toBe(false);
  });

  it('returns false for empty / non-string', () => {
    expect(isLegacyHash('')).toBe(false);
    expect(isLegacyHash(null)).toBe(false);
    expect(isLegacyHash(undefined)).toBe(false);
  });
});
