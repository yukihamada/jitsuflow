/**
 * JitsuFlow API テストスクリプト
 * 主要なAPIエンドポイントの動作確認
 */

const API_BASE_URL = 'https://jitsuflow-worker.yukihamada.workers.dev/api';

// テストユーザー情報
const testUser = {
  email: 'test' + Date.now() + '@example.com',
  password: 'testpass123',
  name: 'テストユーザー',
  phone: '090-1234-5678'
};

let authToken = null;

// カラー出力用のヘルパー
const colors = {
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  reset: '\x1b[0m'
};

function log(message, type = 'info') {
  const color = type === 'success' ? colors.green : type === 'error' ? colors.red : colors.yellow;
  console.log(`${color}${message}${colors.reset}`);
}

// APIリクエストヘルパー
async function apiRequest(endpoint, options = {}) {
  const url = `${API_BASE_URL}${endpoint}`;
  const headers = {
    'Content-Type': 'application/json',
    ...options.headers
  };
  
  if (authToken) {
    headers['Authorization'] = `Bearer ${authToken}`;
  }
  
  try {
    const response = await fetch(url, {
      ...options,
      headers,
      body: options.body ? JSON.stringify(options.body) : undefined
    });
    
    const data = await response.json();
    
    if (!response.ok) {
      throw new Error(data.error || data.message || 'Request failed');
    }
    
    return { success: true, data, status: response.status };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

// テスト実行
async function runTests() {
  log('=== JitsuFlow API テスト開始 ===\n', 'info');
  
  // 1. ヘルスチェック
  log('1. ヘルスチェックテスト', 'info');
  const healthResult = await apiRequest('/health');
  if (healthResult.success) {
    log('✓ ヘルスチェック成功', 'success');
    console.log('  Response:', healthResult.data);
  } else {
    log('✗ ヘルスチェック失敗: ' + healthResult.error, 'error');
  }
  
  // 2. ユーザー登録
  log('\n2. ユーザー登録テスト', 'info');
  const registerResult = await apiRequest('/users/register', {
    method: 'POST',
    body: testUser
  });
  if (registerResult.success) {
    log('✓ ユーザー登録成功', 'success');
    authToken = registerResult.data.token;
    console.log('  User ID:', registerResult.data.user.id);
  } else {
    log('✗ ユーザー登録失敗: ' + registerResult.error, 'error');
  }
  
  // 3. ログイン
  log('\n3. ログインテスト', 'info');
  const loginResult = await apiRequest('/users/login', {
    method: 'POST',
    body: {
      email: testUser.email,
      password: testUser.password
    }
  });
  if (loginResult.success) {
    log('✓ ログイン成功', 'success');
    authToken = loginResult.data.token;
  } else {
    log('✗ ログイン失敗: ' + loginResult.error, 'error');
  }
  
  // 4. 道場一覧取得
  log('\n4. 道場一覧取得テスト', 'info');
  const dojosResult = await apiRequest('/dojos');
  if (dojosResult.success) {
    log('✓ 道場一覧取得成功', 'success');
    console.log('  道場数:', dojosResult.data.dojos.length);
  } else {
    log('✗ 道場一覧取得失敗: ' + dojosResult.error, 'error');
  }
  
  // 5. 商品一覧取得
  log('\n5. 商品一覧取得テスト', 'info');
  const productsResult = await apiRequest('/products?limit=5');
  if (productsResult.success) {
    log('✓ 商品一覧取得成功', 'success');
    console.log('  商品数:', productsResult.data.products.length);
    if (productsResult.data.products.length > 0) {
      console.log('  最初の商品:', productsResult.data.products[0].name);
    }
  } else {
    log('✗ 商品一覧取得失敗: ' + productsResult.error, 'error');
  }
  
  // 6. カート取得
  log('\n6. カート取得テスト', 'info');
  const cartResult = await apiRequest('/cart');
  if (cartResult.success) {
    log('✓ カート取得成功', 'success');
    console.log('  カート内アイテム数:', cartResult.data.items.length);
  } else {
    log('✗ カート取得失敗: ' + cartResult.error, 'error');
  }
  
  // 7. 商品をカートに追加
  if (productsResult.success && productsResult.data.products.length > 0) {
    log('\n7. カートに商品追加テスト', 'info');
    const firstProduct = productsResult.data.products[0];
    const addToCartResult = await apiRequest('/cart/add', {
      method: 'POST',
      body: {
        product_id: firstProduct.id,
        quantity: 1
      }
    });
    if (addToCartResult.success) {
      log('✓ カートに商品追加成功', 'success');
      console.log('  追加した商品:', firstProduct.name);
    } else {
      log('✗ カートに商品追加失敗: ' + addToCartResult.error, 'error');
    }
  }
  
  // 8. ビデオ一覧取得
  log('\n8. ビデオ一覧取得テスト', 'info');
  const videosResult = await apiRequest('/videos');
  if (videosResult.success) {
    log('✓ ビデオ一覧取得成功', 'success');
    console.log('  ビデオ数:', videosResult.data.videos.length);
  } else {
    log('✗ ビデオ一覧取得失敗: ' + videosResult.error, 'error');
  }
  
  // 9. レンタル品一覧取得
  log('\n9. レンタル品一覧取得テスト', 'info');
  const rentalsResult = await apiRequest('/dojo-mode/1/rentals');
  if (rentalsResult.success) {
    log('✓ レンタル品一覧取得成功', 'success');
    console.log('  レンタル品数:', rentalsResult.data.rentals.length);
  } else {
    log('✗ レンタル品一覧取得失敗: ' + rentalsResult.error, 'error');
  }
  
  // 10. 予約作成テスト
  log('\n10. 予約作成テスト', 'info');
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  const bookingResult = await apiRequest('/dojo/bookings', {
    method: 'POST',
    body: {
      dojo_id: 1,
      class_type: 'ベーシッククラス',
      booking_date: tomorrow.toISOString().split('T')[0],
      booking_time: '19:00'
    }
  });
  if (bookingResult.success) {
    log('✓ 予約作成成功', 'success');
    console.log('  予約ID:', bookingResult.data.booking.id);
  } else {
    log('✗ 予約作成失敗: ' + bookingResult.error, 'error');
  }
  
  log('\n=== テスト完了 ===', 'info');
}

// テスト実行
runTests().catch(error => {
  log('テスト実行中にエラーが発生しました: ' + error.message, 'error');
});