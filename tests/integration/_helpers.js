/**
 * Integration test harness for the JitsuFlow Worker.
 *
 * Spins up Miniflare with an in-memory D1, KV, and R2, applies the
 * minimal test schema, and exposes helpers for seeding rows and
 * issuing authenticated requests against the real Worker entrypoint.
 *
 * Each test should call `await createTestEnv()` in `beforeEach` and
 * `await env.dispose()` in `afterEach` to keep cases hermetic.
 */

import { Miniflare } from 'miniflare';
import { build } from 'esbuild';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, '../..');
const SCHEMA_SQL = readFileSync(resolve(__dirname, '_schema.sql'), 'utf8');
const WORKER_ENTRY = resolve(REPO_ROOT, 'src/index.js');

let cachedWorkerScript = null;

async function getWorkerScript() {
  if (cachedWorkerScript) return cachedWorkerScript;
  const result = await build({
    entryPoints: [WORKER_ENTRY],
    bundle: true,
    format: 'esm',
    target: 'esnext',
    platform: 'neutral',
    conditions: ['worker', 'browser'],
    write: false,
    logLevel: 'silent',
    external: ['cloudflare:*', 'node:*']
  });
  cachedWorkerScript = result.outputFiles[0].text;
  return cachedWorkerScript;
}

function splitSqlStatements(sql) {
  // Strip line comments first, then split on `;` at end-of-line. Keep
  // _schema.sql free of multi-line statements that contain `;` inside
  // strings.
  const stripped = sql
    .split('\n')
    .filter(line => !line.trim().startsWith('--'))
    .join('\n');
  return stripped
    .split(/;\s*(?:\r?\n|$)/)
    .map(s => s.trim())
    .filter(s => s.length > 0);
}

const DEFAULT_BINDINGS = {
  ENVIRONMENT: 'test',
  JWT_SECRET: 'test-jwt-secret',
  STRIPE_SECRET_KEY: 'sk_test_dummy',
  STRIPE_WEBHOOK_SECRET: 'whsec_test_dummy',
  RESEND_API_KEY: 'resend_test_dummy',
  SLACK_WEBHOOK_URL: '',
  OPENAI_API_KEY: 'sk-test-dummy',
  GROQ_API_KEY: 'gsk_test_dummy'
};

/**
 * Create an isolated Miniflare environment with schema applied.
 *
 * @param {object} [options]
 * @param {object} [options.bindings] - Override env bindings.
 * @returns {Promise<{mf: Miniflare, db: D1Database, fetch: Function, dispose: Function}>}
 */
// Strip undefined values so a test passing `{ JWT_SECRET: undefined }`
// effectively unsets the binding (Miniflare's zod schema rejects
// undefined-valued bindings outright).
function pruneUndefined(obj) {
  return Object.fromEntries(
    Object.entries(obj).filter(([, v]) => v !== undefined)
  );
}

export async function createTestEnv(options = {}) {
  const script = await getWorkerScript();

  const mf = new Miniflare({
    modules: true,
    script,
    scriptPath: WORKER_ENTRY,
    compatibilityDate: '2024-09-23',
    compatibilityFlags: ['nodejs_compat'],
    d1Databases: { DB: 'test-db' },
    kvNamespaces: ['SESSIONS'],
    r2Buckets: ['BUCKET'],
    bindings: pruneUndefined({
      ...DEFAULT_BINDINGS,
      ...(options.bindings || {})
    })
  });

  const db = await mf.getD1Database('DB');

  for (const stmt of splitSqlStatements(SCHEMA_SQL)) {
    await db.prepare(stmt).run();
  }

  const fetch = (path, init) =>
    mf.dispatchFetch(`http://localhost${path}`, init);

  return {
    mf,
    db,
    fetch,
    dispose: () => mf.dispose()
  };
}

/**
 * Insert a user row directly. Use when you need a pre-existing account
 * with a specific password_hash format (e.g. legacy btoa hash).
 *
 * @param {D1Database} db
 * @param {object} user
 * @returns {Promise<number>} inserted user id
 */
export async function seedUser(db, user = {}) {
  const {
    email = `user-${Math.random().toString(36).slice(2, 10)}@example.com`,
    passwordHash,
    name = 'Test User',
    phone = null,
    role = 'user',
    isActive = 1
  } = user;

  if (!passwordHash) {
    throw new Error('seedUser requires passwordHash');
  }

  const now = new Date().toISOString();
  const result = await db.prepare(
    `INSERT INTO users
       (email, password_hash, name, phone, role, is_active, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
  ).bind(email, passwordHash, name, phone, role, isActive, now, now).run();

  return { id: result.meta.last_row_id, email };
}

/**
 * Issue an authenticated JSON request against the Worker.
 *
 * @param {Function} fetch - The `fetch` returned from createTestEnv.
 * @param {string} method
 * @param {string} path
 * @param {object} [opts]
 * @param {string} [opts.token]
 * @param {object} [opts.body]
 * @param {object} [opts.headers]
 */
export async function authedRequest(fetch, method, path, opts = {}) {
  const { token, body, headers = {} } = opts;
  const init = {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...headers
    }
  };
  if (body !== undefined) init.body = JSON.stringify(body);
  return fetch(path, init);
}
