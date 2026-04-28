/**
 * R2 presigned URL generation using AWS SigV4 (R2 is S3-compatible).
 *
 * The previous stub returned `https://...?presigned=true`, which any
 * client could hit unauthenticated since R2 buckets default to private
 * — uploads/reads through that URL silently failed in production.
 *
 * Required env bindings (set via `wrangler secret put` and
 * `account_id` in wrangler.toml):
 *   - R2_ACCOUNT_ID         (Cloudflare account id)
 *   - R2_ACCESS_KEY_ID      (issued in Cloudflare dashboard → R2 → Manage API tokens)
 *   - R2_SECRET_ACCESS_KEY  (paired secret, "Save in Cloudflare Workers")
 *   - R2_BUCKET_NAME        (e.g. "jitsuflow-assets")
 */

import { AwsClient } from 'aws4fetch';

const DEFAULT_EXPIRY_SECONDS = 3600;

function r2Endpoint({ accountId, bucketName, key }) {
  return `https://${bucketName}.${accountId}.r2.cloudflarestorage.com/${encodeURI(key)}`;
}

function readEnv(env) {
  const required = ['R2_ACCOUNT_ID', 'R2_ACCESS_KEY_ID', 'R2_SECRET_ACCESS_KEY', 'R2_BUCKET_NAME'];
  const missing = required.filter(k => !env?.[k]);
  if (missing.length > 0) {
    throw new Error(`R2 presigned URL requires bindings: ${missing.join(', ')}`);
  }
  return {
    accountId: env.R2_ACCOUNT_ID,
    accessKeyId: env.R2_ACCESS_KEY_ID,
    secretAccessKey: env.R2_SECRET_ACCESS_KEY,
    bucketName: env.R2_BUCKET_NAME
  };
}

async function presignR2(env, { key, method, expiresInSeconds }) {
  const { accountId, accessKeyId, secretAccessKey, bucketName } = readEnv(env);
  const client = new AwsClient({
    accessKeyId,
    secretAccessKey,
    service: 's3',
    region: 'auto'
  });
  const url = new URL(r2Endpoint({ accountId, bucketName, key }));
  url.searchParams.set('X-Amz-Expires', String(expiresInSeconds ?? DEFAULT_EXPIRY_SECONDS));
  const signed = await client.sign(
    new Request(url, { method }),
    { aws: { signQuery: true } }
  );
  return signed.url;
}

/**
 * Presigned URL for uploading an object via PUT.
 * @param {object} env - Worker env with R2_* bindings.
 * @param {string} key - Object key inside the bucket.
 * @param {object} [options]
 * @param {number} [options.expiresInSeconds=3600]
 */
export function generatePresignedPutUrl(env, key, options = {}) {
  return presignR2(env, {
    key,
    method: 'PUT',
    expiresInSeconds: options.expiresInSeconds
  });
}

/**
 * Presigned URL for downloading an object via GET.
 */
export function generatePresignedGetUrl(env, key, options = {}) {
  return presignR2(env, {
    key,
    method: 'GET',
    expiresInSeconds: options.expiresInSeconds
  });
}
