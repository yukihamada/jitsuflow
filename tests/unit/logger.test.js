import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { logInfo, logWarn, logError } from '../../src/utils/logger.js';

function captureConsole() {
  const out = { log: [], error: [] };
  const origLog = console.log;
  const origErr = console.error;
  console.log = (line) => out.log.push(line);
  console.error = (line) => out.error.push(line);
  return {
    out,
    restore() {
      console.log = origLog;
      console.error = origErr;
    }
  };
}

describe('logger', () => {
  let cap;

  beforeEach(() => {
    cap = captureConsole();
  });

  afterEach(() => {
    cap.restore();
  });

  it('emits a JSON line with ts/level/msg for logInfo', () => {
    logInfo('hello', { kind: 'test', n: 42 });
    expect(cap.out.log).toHaveLength(1);
    const parsed = JSON.parse(cap.out.log[0]);
    expect(parsed.level).toBe('info');
    expect(parsed.msg).toBe('hello');
    expect(parsed.kind).toBe('test');
    expect(parsed.n).toBe(42);
    expect(parsed.ts).toMatch(/^\d{4}-\d{2}-\d{2}T/);
  });

  it('emits to console.error for logError', () => {
    logError('boom', { kind: 'auth' });
    expect(cap.out.error).toHaveLength(1);
    expect(cap.out.log).toHaveLength(0);
    expect(JSON.parse(cap.out.error[0]).level).toBe('error');
  });

  it('emits warn level via console.log', () => {
    logWarn('warning', {});
    expect(JSON.parse(cap.out.log[0]).level).toBe('warn');
  });

  it('redacts sensitive context keys', () => {
    logInfo('event', {
      password: 'plaintext',
      password_hash: 'pbkdf2$...',
      jwt_secret: 'leak',
      authorization: 'Bearer abc',
      safe: 'ok'
    });
    const parsed = JSON.parse(cap.out.log[0]);
    expect(parsed.password).toBe('[REDACTED]');
    expect(parsed.password_hash).toBe('[REDACTED]');
    expect(parsed.jwt_secret).toBe('[REDACTED]');
    expect(parsed.authorization).toBe('[REDACTED]');
    expect(parsed.safe).toBe('ok');
  });

  it('redaction is case-insensitive on keys', () => {
    logInfo('event', { Authorization: 'x', PASSWORD: 'y' });
    const parsed = JSON.parse(cap.out.log[0]);
    expect(parsed.Authorization).toBe('[REDACTED]');
    expect(parsed.PASSWORD).toBe('[REDACTED]');
  });

  it('redacts nested sensitive keys (objects and arrays)', () => {
    logInfo('event', {
      kind: 'webhook',
      payload: {
        id: 'evt_1',
        data: {
          object: {
            id: 'pi_1',
            client_secret: 'sk_should_not_appear',
            // nested 'password' deep inside an object
            customer: { email: 'a@b.c', password: 'plaintext' }
          }
        }
      },
      arr: [
        { authorization: 'Bearer abc' }
      ]
    });
    const parsed = JSON.parse(cap.out.log[0]);
    expect(parsed.kind).toBe('webhook');
    expect(parsed.payload.id).toBe('evt_1');
    expect(parsed.payload.data.object.id).toBe('pi_1');
    expect(parsed.payload.data.object.customer.email).toBe('a@b.c');
    expect(parsed.payload.data.object.customer.password).toBe('[REDACTED]');
    expect(parsed.arr[0].authorization).toBe('[REDACTED]');
  });

  it('falls back gracefully when context is unserializable', () => {
    const cyclic = {};
    cyclic.self = cyclic;
    logError('cycle', cyclic);
    expect(cap.out.error).toHaveLength(1);
    const parsed = JSON.parse(cap.out.error[0]);
    expect(parsed._err).toBe('context_unserializable');
    expect(parsed.msg).toBe('cycle');
  });

  it('omits context keys when no context passed', () => {
    logInfo('lone');
    const parsed = JSON.parse(cap.out.log[0]);
    expect(parsed.msg).toBe('lone');
    expect(parsed.level).toBe('info');
  });
});
