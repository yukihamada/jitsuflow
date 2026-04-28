import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { createTestEnv } from './_helpers.js';

/**
 * Stripe re-delivers webhooks on any non-2xx and sometimes on 2xx too
 * (after retries cross). The handler must treat the same event ID as a
 * no-op when the affected row is already in a terminal state.
 *
 * NOTE: signature verification will be added once PR #1 lands; in the
 * meantime the handler accepts an unsigned body, which is what these
 * tests exercise.
 */

async function deliverWebhook(env, payload) {
  return env.fetch('/api/payments/webhook', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload)
  });
}

async function seedPayment(env, { paymentIntentId, status = 'pending', orderId = 1, amount = 1000 }) {
  await env.db.prepare(`
    INSERT INTO orders (id, user_id, order_number, status, payment_status, total_amount, created_at, updated_at)
    VALUES (?, 1, ?, 'pending', 'pending', ?, ?, ?)
  `).bind(orderId, `JF-${orderId}`, amount, new Date().toISOString(), new Date().toISOString()).run();

  await env.db.prepare(`
    INSERT INTO payments
      (user_id, order_id, payment_type, amount, currency, payment_method, stripe_payment_intent_id, status, created_at)
    VALUES (1, ?, 'order', ?, 'JPY', 'stripe', ?, ?, ?)
  `).bind(orderId, amount, paymentIntentId, status, new Date().toISOString()).run();
}

describe('integration: Stripe webhook idempotency', () => {
  let env;

  beforeEach(async () => {
    env = await createTestEnv();
  });

  afterEach(async () => {
    await env.dispose();
  });

  it('processes payment_intent.succeeded once and skips a duplicate delivery', async () => {
    const piId = 'pi_test_dup_001';
    await seedPayment(env, { paymentIntentId: piId });

    const event = {
      id: 'evt_1',
      type: 'payment_intent.succeeded',
      data: { object: { id: piId, metadata: { order_id: '1' } } }
    };

    const first = await deliverWebhook(env, event);
    expect(first.status).toBe(200);

    const afterFirst = await env.db.prepare(
      'SELECT status, paid_at FROM payments WHERE stripe_payment_intent_id = ?'
    ).bind(piId).first();
    expect(afterFirst.status).toBe('completed');
    expect(afterFirst.paid_at).toBeTruthy();
    const firstPaidAt = afterFirst.paid_at;

    // Sleep long enough for an ISO timestamp to differ
    await new Promise(r => setTimeout(r, 20));

    const second = await deliverWebhook(env, event);
    expect(second.status).toBe(200);

    const afterSecond = await env.db.prepare(
      'SELECT status, paid_at FROM payments WHERE stripe_payment_intent_id = ?'
    ).bind(piId).first();
    expect(afterSecond.status).toBe('completed');
    // paid_at must NOT have been rewritten by the duplicate
    expect(afterSecond.paid_at).toBe(firstPaidAt);
  });

  it('processes payment_intent.payment_failed once and skips a duplicate', async () => {
    const piId = 'pi_test_fail_001';
    await seedPayment(env, { paymentIntentId: piId });

    const event = {
      id: 'evt_2',
      type: 'payment_intent.payment_failed',
      data: { object: { id: piId, metadata: { order_id: '1' } } }
    };

    const first = await deliverWebhook(env, event);
    expect(first.status).toBe(200);

    const afterFirst = await env.db.prepare(
      'SELECT status, updated_at FROM payments WHERE stripe_payment_intent_id = ?'
    ).bind(piId).first();
    expect(afterFirst.status).toBe('failed');
    const firstUpdatedAt = afterFirst.updated_at;

    await new Promise(r => setTimeout(r, 20));

    const second = await deliverWebhook(env, event);
    expect(second.status).toBe(200);

    const afterSecond = await env.db.prepare(
      'SELECT status, updated_at FROM payments WHERE stripe_payment_intent_id = ?'
    ).bind(piId).first();
    expect(afterSecond.status).toBe('failed');
    expect(afterSecond.updated_at).toBe(firstUpdatedAt);
  });

  it('still processes a fresh payment intent when an unrelated one is already completed', async () => {
    await seedPayment(env, { paymentIntentId: 'pi_old', status: 'completed', orderId: 1 });
    await seedPayment(env, { paymentIntentId: 'pi_new', status: 'pending', orderId: 2 });

    const event = {
      id: 'evt_3',
      type: 'payment_intent.succeeded',
      data: { object: { id: 'pi_new', metadata: { order_id: '2' } } }
    };

    const res = await deliverWebhook(env, event);
    expect(res.status).toBe(200);

    const newPayment = await env.db.prepare(
      'SELECT status FROM payments WHERE stripe_payment_intent_id = ?'
    ).bind('pi_new').first();
    expect(newPayment.status).toBe('completed');
  });
});
