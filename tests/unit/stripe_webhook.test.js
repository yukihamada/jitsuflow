import { describe, it, expect } from 'vitest';
import { verifyStripeSignature, WebhookConfigError } from '../../src/utils/stripe_webhook.js';

const SECRET = 'whsec_test_secret';

async function hmacHex(secret, payload) {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );
  const sig = await crypto.subtle.sign('HMAC', key, encoder.encode(payload));
  return Array.from(new Uint8Array(sig))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');
}

async function buildHeader(body, { secret = SECRET, timestamp, signature } = {}) {
  const ts = timestamp ?? Math.floor(Date.now() / 1000);
  const sig = signature ?? await hmacHex(secret, `${ts}.${body}`);
  return { header: `t=${ts},v1=${sig}`, timestamp: ts };
}

describe('verifyStripeSignature', () => {
  const body = JSON.stringify({ id: 'evt_1', type: 'payment_intent.succeeded' });

  it('accepts a valid signature and returns the parsed event', async () => {
    const { header, timestamp } = await buildHeader(body);
    const event = await verifyStripeSignature(body, header, SECRET, { nowSeconds: timestamp });
    expect(event.id).toBe('evt_1');
    expect(event.type).toBe('payment_intent.succeeded');
  });

  it('accepts when multiple v1 candidates are present and one matches', async () => {
    const ts = Math.floor(Date.now() / 1000);
    const valid = await hmacHex(SECRET, `${ts}.${body}`);
    const header = `t=${ts},v1=${'0'.repeat(64)},v1=${valid}`;
    const event = await verifyStripeSignature(body, header, SECRET, { nowSeconds: ts });
    expect(event.id).toBe('evt_1');
  });

  it('rejects when the body has been tampered with', async () => {
    const { header, timestamp } = await buildHeader(body);
    const tampered = body.replace('evt_1', 'evt_attacker');
    await expect(
      verifyStripeSignature(tampered, header, SECRET, { nowSeconds: timestamp })
    ).rejects.toThrow(/does not match/);
  });

  it('rejects when signed with a different secret', async () => {
    const { header, timestamp } = await buildHeader(body, { secret: 'whsec_other' });
    await expect(
      verifyStripeSignature(body, header, SECRET, { nowSeconds: timestamp })
    ).rejects.toThrow(/does not match/);
  });

  it('rejects timestamps too far in the past (replay protection)', async () => {
    const { header, timestamp } = await buildHeader(body);
    await expect(
      verifyStripeSignature(body, header, SECRET, { nowSeconds: timestamp + 10_000 })
    ).rejects.toThrow(/tolerance/);
  });

  it('rejects timestamps too far in the future (clock-skew protection)', async () => {
    // Symmetric to the past-side check: a header with t=now+10000 must
    // also be rejected if the verifier's clock is "earlier" by 10k.
    const { header, timestamp } = await buildHeader(body);
    await expect(
      verifyStripeSignature(body, header, SECRET, { nowSeconds: timestamp - 10_000 })
    ).rejects.toThrow(/tolerance/);
  });

  it('rejects malformed headers', async () => {
    await expect(
      verifyStripeSignature(body, 'not-a-real-header', SECRET)
    ).rejects.toThrow(/Malformed/);
  });

  it('rejects when the header is missing', async () => {
    await expect(
      verifyStripeSignature(body, null, SECRET)
    ).rejects.toThrow(/Missing Stripe-Signature/);
  });

  it('throws WebhookConfigError when the secret is not configured', async () => {
    // Distinct error class so the HTTP handler can return 500 (ops alert)
    // instead of 400 (Stripe-facing) — Stripe will retry, the retry pile-up
    // is the signal.
    const { header } = await buildHeader(body);
    await expect(
      verifyStripeSignature(body, header, '')
    ).rejects.toBeInstanceOf(WebhookConfigError);
    await expect(
      verifyStripeSignature(body, header, undefined)
    ).rejects.toBeInstanceOf(WebhookConfigError);
  });

  it('rejects when the verified payload is not valid JSON', async () => {
    const malformed = '{not json';
    const { header, timestamp } = await buildHeader(malformed);
    await expect(
      verifyStripeSignature(malformed, header, SECRET, { nowSeconds: timestamp })
    ).rejects.toThrow(/not valid JSON/);
  });
});
