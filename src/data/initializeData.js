/**
 * データ初期化スクリプト
 * サンプルデータをCloudflare D1データベースに挿入
 */

import { insertSampleProducts } from './sampleProducts.js';
import { insertSampleRentals } from './sampleRentals.js';

/**
 * すべてのサンプルデータを初期化
 * @param {Database} db - Cloudflare D1データベース
 */
export async function initializeAllSampleData(db) {
  try {
    console.log('Starting data initialization...');

    // 既存データのクリア（オプション）
    // await clearExistingData(db);

    // 商品データの挿入
    console.log('Inserting sample products...');
    await insertSampleProducts(db);
    console.log('Sample products inserted successfully');

    // レンタルデータの挿入
    console.log('Inserting sample rentals...');
    await insertSampleRentals(db);
    console.log('Sample rentals inserted successfully');

    console.log('Data initialization completed successfully!');

    // 挿入されたデータの確認
    const productCount = await db.prepare('SELECT COUNT(*) as count FROM products').first();
    const rentalCount = await db.prepare('SELECT COUNT(*) as count FROM rentals').first();

    console.log(`Total products: ${productCount.count}`);
    console.log(`Total rentals: ${rentalCount.count}`);

  } catch (error) {
    console.error('Error during data initialization:', error);
    throw error;
  }
}

// clearExistingData function removed - not used in production

/**
 * 開発環境用のデータ初期化エンドポイント
 * 注意: 本番環境では無効化すること
 */
export async function handleDataInitialization(request, env) {
  // 環境チェック（本番環境では無効化）
  if (env.ENVIRONMENT === 'production') {
    return new Response(JSON.stringify({
      error: 'Data initialization is disabled in production'
    }), {
      status: 403,
      headers: { 'Content-Type': 'application/json' }
    });
  }

  // 認証チェック（管理者のみ）
  if (!request.user || request.user.role !== 'admin') {
    return new Response(JSON.stringify({
      error: 'Unauthorized: Admin access required'
    }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' }
    });
  }

  try {
    await initializeAllSampleData(env.DB);

    return new Response(JSON.stringify({
      message: 'Sample data initialized successfully'
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    return new Response(JSON.stringify({
      error: 'Failed to initialize data',
      message: error.message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}
