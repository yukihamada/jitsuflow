import { describe, it, expect } from 'vitest';
import {
  generatePresignedPutUrl,
  generatePresignedGetUrl
} from '../../src/utils/r2_presigned.js';

const TEST_ENV = {
  R2_ACCOUNT_ID: '46bf2542468db352a9741f14b84d2744',
  R2_ACCESS_KEY_ID: 'AKIAIOSFODNN7TESTKEY',
  R2_SECRET_ACCESS_KEY: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYTESTKEY',
  R2_BUCKET_NAME: 'jitsuflow-assets'
};

function assertSigV4Url(urlStr, { method, key, expiresIn = 3600 }) {
  const url = new URL(urlStr);
  expect(url.host).toBe(`${TEST_ENV.R2_BUCKET_NAME}.${TEST_ENV.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`);
  expect(url.pathname).toBe(`/${key}`);
  expect(url.searchParams.get('X-Amz-Algorithm')).toBe('AWS4-HMAC-SHA256');
  expect(url.searchParams.get('X-Amz-Expires')).toBe(String(expiresIn));
  // Credential is "<key>/<date>/<region>/<service>/aws4_request"
  expect(url.searchParams.get('X-Amz-Credential')).toMatch(
    new RegExp(`^${TEST_ENV.R2_ACCESS_KEY_ID}/\\d{8}/auto/s3/aws4_request$`)
  );
  expect(url.searchParams.get('X-Amz-Date')).toMatch(/^\d{8}T\d{6}Z$/);
  expect(url.searchParams.get('X-Amz-Signature')).toMatch(/^[0-9a-f]{64}$/);
  // Method is implicit in the signature, not the URL — we just confirm
  // a SignedHeaders param exists and references host.
  expect(url.searchParams.get('X-Amz-SignedHeaders')).toContain('host');
  // The mock method does not show up in the URL itself; this argument
  // is just used to keep tests parameterizable.
  expect(method).toMatch(/^(GET|PUT)$/);
}

describe('generatePresignedPutUrl', () => {
  it('returns a SigV4 URL with default 1h expiry', async () => {
    const url = await generatePresignedPutUrl(TEST_ENV, 'videos/abc-123');
    assertSigV4Url(url, { method: 'PUT', key: 'videos/abc-123' });
  });

  it('honours a custom expiry', async () => {
    const url = await generatePresignedPutUrl(TEST_ENV, 'videos/x', { expiresInSeconds: 60 });
    assertSigV4Url(url, { method: 'PUT', key: 'videos/x', expiresIn: 60 });
  });

  it('produces a different signature for a different key', async () => {
    const a = await generatePresignedPutUrl(TEST_ENV, 'videos/a');
    const b = await generatePresignedPutUrl(TEST_ENV, 'videos/b');
    expect(new URL(a).searchParams.get('X-Amz-Signature'))
      .not.toBe(new URL(b).searchParams.get('X-Amz-Signature'));
  });

  it('throws when an R2 binding is missing', async () => {
    const incomplete = { ...TEST_ENV, R2_SECRET_ACCESS_KEY: undefined };
    await expect(generatePresignedPutUrl(incomplete, 'videos/x'))
      .rejects.toThrow(/R2_SECRET_ACCESS_KEY/);
  });
});

describe('generatePresignedGetUrl', () => {
  it('returns a SigV4 URL', async () => {
    const url = await generatePresignedGetUrl(TEST_ENV, 'videos/abc-123');
    assertSigV4Url(url, { method: 'GET', key: 'videos/abc-123' });
  });
});
