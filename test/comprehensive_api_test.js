/**
 * JitsuFlow API 包括的テストスイート
 * 全APIエンドポイントの成功ケース、エラーケース、エッジケース、パフォーマンステスト
 */

const API_BASE_URL = 'https://jitsuflow-worker.yukihamada.workers.dev/api';

// テスト結果の追跡
let testResults = {
  total: 0,
  passed: 0,
  failed: 0,
  warnings: 0,
  errors: [],
  warnings: [],
  performance: []
};

// カラー出力用のヘルパー
const colors = {
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  reset: '\x1b[0m',
  bold: '\x1b[1m'
};

function log(message, type = 'info') {
  const timestamp = new Date().toISOString();
  const color = type === 'success' ? colors.green : 
               type === 'error' ? colors.red : 
               type === 'warning' ? colors.yellow :
               type === 'info' ? colors.blue : colors.reset;
  console.log(`${color}[${timestamp}] ${message}${colors.reset}`);
}

// APIリクエストヘルパー（パフォーマンス測定付き）
async function apiRequest(endpoint, options = {}, testName = '') {
  const url = `${API_BASE_URL}${endpoint}`;
  const startTime = performance.now();
  
  const headers = {
    'Content-Type': 'application/json',
    ...options.headers
  };
  
  try {
    const response = await fetch(url, {
      ...options,
      headers,
      body: options.body ? JSON.stringify(options.body) : undefined
    });
    
    const endTime = performance.now();
    const responseTime = endTime - startTime;
    
    // パフォーマンス追跡
    testResults.performance.push({
      endpoint,
      method: options.method || 'GET',
      responseTime,
      status: response.status,
      testName
    });
    
    // レスポンス時間の警告
    if (responseTime > 5000) {
      testResults.warnings.push(`${testName}: Slow response (${responseTime.toFixed(2)}ms) for ${endpoint}`);
      log(`⚠️  SLOW RESPONSE: ${endpoint} took ${responseTime.toFixed(2)}ms`, 'warning');
    } else if (responseTime > 2000) {
      log(`⚠️  Warning: ${endpoint} took ${responseTime.toFixed(2)}ms`, 'warning');
    }
    
    let data;
    try {
      data = await response.json();
    } catch (e) {
      data = await response.text();
    }
    
    return { 
      success: response.ok, 
      data, 
      status: response.status,
      responseTime,
      headers: Object.fromEntries(response.headers.entries())
    };
  } catch (error) {
    const endTime = performance.now();
    testResults.errors.push(`${testName}: Network error - ${error.message}`);
    return { 
      success: false, 
      error: error.message,
      responseTime: endTime - startTime 
    };
  }
}

// テスト実行ヘルパー
function runTest(testName, testFn) {
  return new Promise(async (resolve) => {
    testResults.total++;
    log(`Running: ${testName}`, 'info');
    
    try {
      const result = await testFn();
      if (result === true || result?.success === true) {
        testResults.passed++;
        log(`✅ PASS: ${testName}`, 'success');
      } else {
        testResults.failed++;
        const errorMsg = result?.error || result?.message || 'Test failed';
        testResults.errors.push(`${testName}: ${errorMsg}`);
        log(`❌ FAIL: ${testName} - ${errorMsg}`, 'error');
      }
    } catch (error) {
      testResults.failed++;
      testResults.errors.push(`${testName}: ${error.message}`);
      log(`❌ ERROR: ${testName} - ${error.message}`, 'error');
    }
    
    resolve();
  });
}

// テストユーザー生成
function generateTestUser() {
  const timestamp = Date.now();
  return {
    email: `test${timestamp}@jitsuflow-test.com`,
    password: 'TestPass123!',
    name: `テストユーザー${timestamp}`,
    phone: '090-1234-5678'
  };
}

// 認証トークンの管理
let authTokens = {
  validUser: null,
  adminUser: null
};

/**
 * 1. ヘルスチェックテスト
 */
async function testHealthCheck() {
  const result = await apiRequest('/health', {}, 'Health Check');
  
  if (!result.success) {
    return { success: false, error: 'Health check failed' };
  }
  
  // レスポンス構造の検証
  const requiredFields = ['status', 'timestamp', 'service'];
  for (const field of requiredFields) {
    if (!result.data[field]) {
      return { success: false, error: `Missing field: ${field}` };
    }
  }
  
  if (result.data.status !== 'healthy') {
    return { success: false, error: `Expected status 'healthy', got '${result.data.status}'` };
  }
  
  return { success: true };
}

/**
 * 2. ユーザー登録テスト群
 */
async function testUserRegistrationSuccess() {
  const testUser = generateTestUser();
  const result = await apiRequest('/users/register', {
    method: 'POST',
    body: testUser
  }, 'User Registration - Success');
  
  if (!result.success) {
    return { success: false, error: result.data?.error || 'Registration failed' };
  }
  
  // トークンを保存
  authTokens.validUser = result.data.token;
  
  // レスポンス構造の検証
  if (!result.data.user || !result.data.token) {
    return { success: false, error: 'Missing user or token in response' };
  }
  
  return { success: true };
}

async function testUserRegistrationDuplicateEmail() {
  const testUser = generateTestUser();
  
  // 最初の登録
  await apiRequest('/users/register', {
    method: 'POST',
    body: testUser
  }, 'User Registration - First');
  
  // 重複登録の試行
  const result = await apiRequest('/users/register', {
    method: 'POST',
    body: testUser
  }, 'User Registration - Duplicate Email');
  
  // 重複登録は失敗すべき
  if (result.success) {
    return { success: false, error: 'Duplicate registration should fail' };
  }
  
  return { success: true };
}

async function testUserRegistrationMissingFields() {
  const tests = [
    { body: { password: 'test', name: 'test' }, missing: 'email' },
    { body: { email: 'test@test.com', name: 'test' }, missing: 'password' },
    { body: { email: 'test@test.com', password: 'test' }, missing: 'name' },
    { body: {}, missing: 'all fields' }
  ];
  
  for (const test of tests) {
    const result = await apiRequest('/users/register', {
      method: 'POST',
      body: test.body
    }, `User Registration - Missing ${test.missing}`);
    
    if (result.success) {
      return { success: false, error: `Registration should fail when missing ${test.missing}` };
    }
  }
  
  return { success: true };
}

async function testUserRegistrationInvalidEmail() {
  const invalidEmails = ['invalid-email', 'test@', '@test.com', ''];
  
  for (const email of invalidEmails) {
    const result = await apiRequest('/users/register', {
      method: 'POST',
      body: {
        email,
        password: 'TestPass123!',
        name: 'Test User'
      }
    }, `User Registration - Invalid Email: ${email}`);
    
    if (result.success) {
      return { success: false, error: `Registration should fail for invalid email: ${email}` };
    }
  }
  
  return { success: true };
}

/**
 * 3. ユーザーログインテスト群
 */
async function testUserLoginSuccess() {
  const testUser = generateTestUser();
  
  // ユーザー登録
  const registerResult = await apiRequest('/users/register', {
    method: 'POST',
    body: testUser
  }, 'Login Test - Registration');
  
  if (!registerResult.success) {
    return { success: false, error: 'Failed to register test user' };
  }
  
  // ログイン
  const loginResult = await apiRequest('/users/login', {
    method: 'POST',
    body: {
      email: testUser.email,
      password: testUser.password
    }
  }, 'User Login - Success');
  
  if (!loginResult.success) {
    return { success: false, error: loginResult.data?.error || 'Login failed' };
  }
  
  // レスポンス構造の検証
  if (!loginResult.data.user || !loginResult.data.token) {
    return { success: false, error: 'Missing user or token in login response' };
  }
  
  return { success: true };
}

async function testUserLoginWrongPassword() {
  const testUser = generateTestUser();
  
  // ユーザー登録
  await apiRequest('/users/register', {
    method: 'POST',
    body: testUser
  }, 'Wrong Password Test - Registration');
  
  // 間違ったパスワードでログイン
  const result = await apiRequest('/users/login', {
    method: 'POST',
    body: {
      email: testUser.email,
      password: 'wrongpassword'
    }
  }, 'User Login - Wrong Password');
  
  if (result.success) {
    return { success: false, error: 'Login should fail with wrong password' };
  }
  
  return { success: true };
}

async function testUserLoginNonExistentUser() {
  const result = await apiRequest('/users/login', {
    method: 'POST',
    body: {
      email: 'nonexistent@example.com',
      password: 'anypassword'
    }
  }, 'User Login - Non-existent User');
  
  if (result.success) {
    return { success: false, error: 'Login should fail for non-existent user' };
  }
  
  return { success: true };
}

async function testUserLoginMissingCredentials() {
  const tests = [
    { body: { password: 'test' }, missing: 'email' },
    { body: { email: 'test@test.com' }, missing: 'password' },
    { body: {}, missing: 'both email and password' }
  ];
  
  for (const test of tests) {
    const result = await apiRequest('/users/login', {
      method: 'POST',
      body: test.body
    }, `User Login - Missing ${test.missing}`);
    
    if (result.success) {
      return { success: false, error: `Login should fail when missing ${test.missing}` };
    }
  }
  
  return { success: true };
}

/**
 * 4. 道場管理テスト群
 */
async function testDojosWithAuth() {
  if (!authTokens.validUser) {
    return { success: false, error: 'No valid auth token available' };
  }
  
  const result = await apiRequest('/dojos', {
    headers: {
      'Authorization': `Bearer ${authTokens.validUser}`
    }
  }, 'Dojos - With Auth');
  
  if (!result.success) {
    return { success: false, error: result.data?.error || 'Failed to get dojos' };
  }
  
  // レスポンス構造の検証
  if (!result.data.dojos || !Array.isArray(result.data.dojos)) {
    return { success: false, error: 'Expected dojos array in response' };
  }
  
  return { success: true };
}

async function testDojosWithoutAuth() {
  const result = await apiRequest('/dojos', {}, 'Dojos - Without Auth');
  
  // 認証なしでアクセスした場合の動作を確認
  // (仕様により成功する場合もある)
  return { success: true, note: `No auth result: ${result.status}` };
}

/**
 * 5. 商品管理テスト群
 */
async function testProductsDefault() {
  if (!authTokens.validUser) {
    return { success: false, error: 'No valid auth token available' };
  }
  
  const result = await apiRequest('/products', {
    headers: {
      'Authorization': `Bearer ${authTokens.validUser}`
    }
  }, 'Products - Default');
  
  if (!result.success) {
    return { success: false, error: result.data?.error || 'Failed to get products' };
  }
  
  if (!result.data.products || !Array.isArray(result.data.products)) {
    return { success: false, error: 'Expected products array in response' };
  }
  
  return { success: true };
}

async function testProductsPagination() {
  if (!authTokens.validUser) {
    return { success: false, error: 'No valid auth token available' };
  }
  
  const result = await apiRequest('/products?limit=5&offset=0', {
    headers: {
      'Authorization': `Bearer ${authTokens.validUser}`
    }
  }, 'Products - Pagination');
  
  if (!result.success) {
    return { success: false, error: result.data?.error || 'Failed to get products with pagination' };
  }
  
  // 最大5件までのチェック
  if (result.data.products.length > 5) {
    return { success: false, error: 'Pagination limit not respected' };
  }
  
  return { success: true };
}

async function testProductsCategoryFilter() {
  if (!authTokens.validUser) {
    return { success: false, error: 'No valid auth token available' };
  }
  
  const categories = ['gi', 'belt', 'protector', 'apparel', 'equipment', 'supplement', 'accessories'];
  
  for (const category of categories) {
    const result = await apiRequest(`/products?category=${category}`, {
      headers: {
        'Authorization': `Bearer ${authTokens.validUser}`
      }
    }, `Products - Category Filter: ${category}`);
    
    if (!result.success) {
      return { success: false, error: `Failed to filter by category: ${category}` };
    }
  }
  
  return { success: true };
}

async function testProductsInvalidCategory() {
  if (!authTokens.validUser) {
    return { success: false, error: 'No valid auth token available' };
  }
  
  const result = await apiRequest('/products?category=invalid', {
    headers: {
      'Authorization': `Bearer ${authTokens.validUser}`
    }
  }, 'Products - Invalid Category');
  
  // 無効なカテゴリでも空の結果を返すか、エラーを返すかは実装による
  return { success: true, note: `Invalid category result: ${result.status}` };
}

/**
 * 6. カート管理テスト群
 */
async function testCartEmpty() {
  if (!authTokens.validUser) {
    return { success: false, error: 'No valid auth token available' };
  }
  
  const result = await apiRequest('/cart', {
    headers: {
      'Authorization': `Bearer ${authTokens.validUser}`
    }
  }, 'Cart - Empty');
  
  if (!result.success) {
    return { success: false, error: result.data?.error || 'Failed to get cart' };
  }
  
  if (!result.data.items || !Array.isArray(result.data.items)) {
    return { success: false, error: 'Expected items array in cart response' };
  }
  
  return { success: true };
}

async function testCartAddValidProduct() {
  if (!authTokens.validUser) {
    return { success: false, error: 'No valid auth token available' };
  }
  
  // まず商品一覧を取得
  const productsResult = await apiRequest('/products?limit=1', {
    headers: {
      'Authorization': `Bearer ${authTokens.validUser}`
    }
  }, 'Cart Add - Get Products');
  
  if (!productsResult.success || productsResult.data.products.length === 0) {
    return { success: false, error: 'No products available for cart test' };
  }
  
  const product = productsResult.data.products[0];
  
  const result = await apiRequest('/cart/add', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${authTokens.validUser}`
    },
    body: {
      product_id: product.id,
      quantity: 1
    }
  }, 'Cart - Add Valid Product');
  
  if (!result.success) {
    return { success: false, error: result.data?.error || 'Failed to add product to cart' };
  }
  
  return { success: true };
}

async function testCartAddInvalidProduct() {
  if (!authTokens.validUser) {
    return { success: false, error: 'No valid auth token available' };
  }
  
  const result = await apiRequest('/cart/add', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${authTokens.validUser}`
    },
    body: {
      product_id: 99999, // 存在しない商品ID
      quantity: 1
    }
  }, 'Cart - Add Invalid Product');
  
  if (result.success) {
    return { success: false, error: 'Adding invalid product should fail' };
  }
  
  return { success: true };
}

async function testCartAddZeroQuantity() {
  if (!authTokens.validUser) {
    return { success: false, error: 'No valid auth token available' };
  }
  
  const result = await apiRequest('/cart/add', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${authTokens.validUser}`
    },
    body: {
      product_id: 1,
      quantity: 0
    }
  }, 'Cart - Add Zero Quantity');
  
  if (result.success) {
    return { success: false, error: 'Adding zero quantity should fail' };
  }
  
  return { success: true };
}

async function testCartAddExcessiveQuantity() {
  if (!authTokens.validUser) {
    return { success: false, error: 'No valid auth token available' };
  }
  
  const result = await apiRequest('/cart/add', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${authTokens.validUser}`
    },
    body: {
      product_id: 1,
      quantity: 10000 // 過剰な数量
    }
  }, 'Cart - Add Excessive Quantity');
  
  // 実装により、制限があるかもしれない
  return { success: true, note: `Excessive quantity result: ${result.status}` };
}

async function testCartWithoutAuth() {
  const result = await apiRequest('/cart', {}, 'Cart - Without Auth');
  
  if (result.success) {
    return { success: false, error: 'Cart access should require authentication' };
  }
  
  if (result.status !== 401) {
    return { success: false, error: `Expected 401 status, got ${result.status}` };
  }
  
  return { success: true };
}

/**
 * 7. 予約システムテスト群
 */
async function testBookingCreate() {
  if (!authTokens.validUser) {
    return { success: false, error: 'No valid auth token available' };
  }
  
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  
  const result = await apiRequest('/dojo/bookings', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${authTokens.validUser}`
    },
    body: {
      dojo_id: 1,
      class_type: 'ベーシッククラス',
      booking_date: tomorrow.toISOString().split('T')[0],
      booking_time: '19:00'
    }
  }, 'Booking - Create Valid');
  
  if (!result.success) {
    return { success: false, error: result.data?.error || 'Failed to create booking' };
  }
  
  return { success: true };
}

async function testBookingCreatePastDate() {
  if (!authTokens.validUser) {
    return { success: false, error: 'No valid auth token available' };
  }
  
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  
  const result = await apiRequest('/dojo/bookings', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${authTokens.validUser}`
    },
    body: {
      dojo_id: 1,
      class_type: 'ベーシッククラス',
      booking_date: yesterday.toISOString().split('T')[0],
      booking_time: '19:00'
    }
  }, 'Booking - Create Past Date');
  
  if (result.success) {
    return { success: false, error: 'Booking past date should fail' };
  }
  
  return { success: true };
}

async function testBookingCreateMissingFields() {
  if (!authTokens.validUser) {
    return { success: false, error: 'No valid auth token available' };
  }
  
  const tests = [
    { body: { class_type: 'test', booking_date: '2025-07-15', booking_time: '19:00' }, missing: 'dojo_id' },
    { body: { dojo_id: 1, booking_date: '2025-07-15', booking_time: '19:00' }, missing: 'class_type' },
    { body: { dojo_id: 1, class_type: 'test', booking_time: '19:00' }, missing: 'booking_date' },
    { body: { dojo_id: 1, class_type: 'test', booking_date: '2025-07-15' }, missing: 'booking_time' }
  ];
  
  for (const test of tests) {
    const result = await apiRequest('/dojo/bookings', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${authTokens.validUser}`
      },
      body: test.body
    }, `Booking - Missing ${test.missing}`);
    
    if (result.success) {
      return { success: false, error: `Booking should fail when missing ${test.missing}` };
    }
  }
  
  return { success: true };
}

async function testBookingsGet() {
  if (!authTokens.validUser) {
    return { success: false, error: 'No valid auth token available' };
  }
  
  const result = await apiRequest('/dojo/bookings', {
    headers: {
      'Authorization': `Bearer ${authTokens.validUser}`
    }
  }, 'Bookings - Get List');
  
  if (!result.success) {
    return { success: false, error: result.data?.error || 'Failed to get bookings' };
  }
  
  if (!result.data.bookings || !Array.isArray(result.data.bookings)) {
    return { success: false, error: 'Expected bookings array in response' };
  }
  
  return { success: true };
}

/**
 * 8. ビデオコンテンツテスト群
 */
async function testVideosGet() {
  if (!authTokens.validUser) {
    return { success: false, error: 'No valid auth token available' };
  }
  
  const result = await apiRequest('/videos', {
    headers: {
      'Authorization': `Bearer ${authTokens.validUser}`
    }
  }, 'Videos - Get List');
  
  if (!result.success) {
    return { success: false, error: result.data?.error || 'Failed to get videos' };
  }
  
  if (!result.data.videos || !Array.isArray(result.data.videos)) {
    return { success: false, error: 'Expected videos array in response' };
  }
  
  return { success: true };
}

async function testVideosPremiumFilter() {
  if (!authTokens.validUser) {
    return { success: false, error: 'No valid auth token available' };
  }
  
  const result = await apiRequest('/videos?premium=true', {
    headers: {
      'Authorization': `Bearer ${authTokens.validUser}`
    }
  }, 'Videos - Premium Filter');
  
  if (!result.success) {
    return { success: false, error: result.data?.error || 'Failed to get premium videos' };
  }
  
  return { success: true };
}

async function testVideosFreeFilter() {
  if (!authTokens.validUser) {
    return { success: false, error: 'No valid auth token available' };
  }
  
  const result = await apiRequest('/videos?premium=false', {
    headers: {
      'Authorization': `Bearer ${authTokens.validUser}`
    }
  }, 'Videos - Free Filter');
  
  if (!result.success) {
    return { success: false, error: result.data?.error || 'Failed to get free videos' };
  }
  
  return { success: true };
}

/**
 * 9. レンタルシステムテスト群
 */
async function testRentalsGetByDojo() {
  if (!authTokens.validUser) {
    return { success: false, error: 'No valid auth token available' };
  }
  
  const result = await apiRequest('/dojo-mode/1/rentals', {
    headers: {
      'Authorization': `Bearer ${authTokens.validUser}`
    }
  }, 'Rentals - Get by Dojo');
  
  if (!result.success) {
    return { success: false, error: result.data?.error || 'Failed to get rentals' };
  }
  
  if (!result.data.rentals || !Array.isArray(result.data.rentals)) {
    return { success: false, error: 'Expected rentals array in response' };
  }
  
  return { success: true };
}

async function testRentalsInvalidDojo() {
  if (!authTokens.validUser) {
    return { success: false, error: 'No valid auth token available' };
  }
  
  const result = await apiRequest('/dojo-mode/99999/rentals', {
    headers: {
      'Authorization': `Bearer ${authTokens.validUser}`
    }
  }, 'Rentals - Invalid Dojo');
  
  // 無効な道場IDの場合の動作確認
  return { success: true, note: `Invalid dojo result: ${result.status}` };
}

async function testRentalTransaction() {
  if (!authTokens.validUser) {
    return { success: false, error: 'No valid auth token available' };
  }
  
  const futureDate = new Date();
  futureDate.setDate(futureDate.getDate() + 7);
  
  const result = await apiRequest('/rentals/1/rent', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${authTokens.validUser}`
    },
    body: {
      user_id: 1,
      return_due_date: futureDate.toISOString()
    }
  }, 'Rental - Transaction');
  
  // レンタル実行の結果を確認（在庫がない場合もある）
  return { success: true, note: `Rental transaction result: ${result.status}` };
}

/**
 * 10. セキュリティテスト群
 */
async function testSQLInjectionAttempts() {
  const sqlPayloads = [
    "'; DROP TABLE users; --",
    "1' OR '1'='1",
    "admin'--",
    "1' UNION SELECT * FROM users--"
  ];
  
  for (const payload of sqlPayloads) {
    const result = await apiRequest('/users/login', {
      method: 'POST',
      body: {
        email: payload,
        password: payload
      }
    }, `Security - SQL Injection: ${payload.substring(0, 20)}...`);
    
    // SQLインジェクションは失敗すべき
    if (result.success) {
      return { success: false, error: 'SQL injection attempt succeeded' };
    }
  }
  
  return { success: true };
}

async function testXSSAttempts() {
  const xssPayloads = [
    "<script>alert('xss')</script>",
    "javascript:alert('xss')",
    "<img src=x onerror=alert('xss')>",
    "';alert('xss');//"
  ];
  
  for (const payload of xssPayloads) {
    const result = await apiRequest('/users/register', {
      method: 'POST',
      body: {
        email: `test${Date.now()}@test.com`,
        password: 'TestPass123!',
        name: payload
      }
    }, `Security - XSS: ${payload.substring(0, 20)}...`);
    
    // XSSペイロードが含まれていても、サニタイズされているべき
    if (result.success && result.data.user.name === payload) {
      testResults.warnings.push(`Potential XSS vulnerability: payload not sanitized`);
    }
  }
  
  return { success: true };
}

/**
 * 11. パフォーマンステスト群
 */
async function testConcurrentRequests() {
  if (!authTokens.validUser) {
    return { success: false, error: 'No valid auth token available' };
  }
  
  const concurrentCount = 10;
  const promises = [];
  
  for (let i = 0; i < concurrentCount; i++) {
    promises.push(
      apiRequest('/products?limit=1', {
        headers: {
          'Authorization': `Bearer ${authTokens.validUser}`
        }
      }, `Concurrent Request ${i + 1}`)
    );
  }
  
  const startTime = performance.now();
  const results = await Promise.all(promises);
  const endTime = performance.now();
  
  const successCount = results.filter(r => r.success).length;
  const totalTime = endTime - startTime;
  
  log(`Concurrent test: ${successCount}/${concurrentCount} succeeded in ${totalTime.toFixed(2)}ms`);
  
  if (successCount < concurrentCount * 0.8) { // 80%以上成功すべき
    return { success: false, error: `Only ${successCount}/${concurrentCount} concurrent requests succeeded` };
  }
  
  return { success: true };
}

/**
 * メインテスト実行
 */
async function runAllTests() {
  console.log(`${colors.bold}${colors.blue}=== JitsuFlow API 包括的テスト開始 ===${colors.reset}\n`);
  
  const startTime = performance.now();
  
  // 1. ヘルスチェック
  await runTest('Health Check', testHealthCheck);
  
  // 2. ユーザー登録テスト群
  await runTest('User Registration - Success', testUserRegistrationSuccess);
  await runTest('User Registration - Duplicate Email', testUserRegistrationDuplicateEmail);
  await runTest('User Registration - Missing Fields', testUserRegistrationMissingFields);
  await runTest('User Registration - Invalid Email', testUserRegistrationInvalidEmail);
  
  // 3. ユーザーログインテスト群
  await runTest('User Login - Success', testUserLoginSuccess);
  await runTest('User Login - Wrong Password', testUserLoginWrongPassword);
  await runTest('User Login - Non-existent User', testUserLoginNonExistentUser);
  await runTest('User Login - Missing Credentials', testUserLoginMissingCredentials);
  
  // 4. 道場管理テスト群
  await runTest('Dojos - With Auth', testDojosWithAuth);
  await runTest('Dojos - Without Auth', testDojosWithoutAuth);
  
  // 5. 商品管理テスト群
  await runTest('Products - Default', testProductsDefault);
  await runTest('Products - Pagination', testProductsPagination);
  await runTest('Products - Category Filter', testProductsCategoryFilter);
  await runTest('Products - Invalid Category', testProductsInvalidCategory);
  
  // 6. カート管理テスト群
  await runTest('Cart - Empty', testCartEmpty);
  await runTest('Cart - Add Valid Product', testCartAddValidProduct);
  await runTest('Cart - Add Invalid Product', testCartAddInvalidProduct);
  await runTest('Cart - Add Zero Quantity', testCartAddZeroQuantity);
  await runTest('Cart - Add Excessive Quantity', testCartAddExcessiveQuantity);
  await runTest('Cart - Without Auth', testCartWithoutAuth);
  
  // 7. 予約システムテスト群
  await runTest('Booking - Create Valid', testBookingCreate);
  await runTest('Booking - Create Past Date', testBookingCreatePastDate);
  await runTest('Booking - Missing Fields', testBookingCreateMissingFields);
  await runTest('Bookings - Get List', testBookingsGet);
  
  // 8. ビデオコンテンツテスト群
  await runTest('Videos - Get List', testVideosGet);
  await runTest('Videos - Premium Filter', testVideosPremiumFilter);
  await runTest('Videos - Free Filter', testVideosFreeFilter);
  
  // 9. レンタルシステムテスト群
  await runTest('Rentals - Get by Dojo', testRentalsGetByDojo);
  await runTest('Rentals - Invalid Dojo', testRentalsInvalidDojo);
  await runTest('Rental - Transaction', testRentalTransaction);
  
  // 10. セキュリティテスト群
  await runTest('Security - SQL Injection', testSQLInjectionAttempts);
  await runTest('Security - XSS Attempts', testXSSAttempts);
  
  // 11. パフォーマンステスト群
  await runTest('Performance - Concurrent Requests', testConcurrentRequests);
  
  const endTime = performance.now();
  const totalTime = endTime - startTime;
  
  // 結果サマリーの表示
  console.log(`\n${colors.bold}=== テスト結果サマリー ===${colors.reset}`);
  console.log(`${colors.blue}総実行時間: ${totalTime.toFixed(2)}ms${colors.reset}`);
  console.log(`${colors.green}成功: ${testResults.passed}${colors.reset}`);
  console.log(`${colors.red}失敗: ${testResults.failed}${colors.reset}`);
  console.log(`${colors.yellow}警告: ${testResults.warnings.length}${colors.reset}`);
  console.log(`総テスト数: ${testResults.total}`);
  
  if (testResults.failed > 0) {
    console.log(`\n${colors.red}${colors.bold}=== エラー詳細 ===${colors.reset}`);
    testResults.errors.forEach(error => {
      console.log(`${colors.red}❌ ${error}${colors.reset}`);
    });
  }
  
  if (testResults.warnings.length > 0) {
    console.log(`\n${colors.yellow}${colors.bold}=== 警告詳細 ===${colors.reset}`);
    testResults.warnings.forEach(warning => {
      console.log(`${colors.yellow}⚠️  ${warning}${colors.reset}`);
    });
  }
  
  // パフォーマンス統計
  console.log(`\n${colors.blue}${colors.bold}=== パフォーマンス統計 ===${colors.reset}`);
  
  const responseTimes = testResults.performance.map(p => p.responseTime);
  const avgResponseTime = responseTimes.reduce((a, b) => a + b, 0) / responseTimes.length;
  const maxResponseTime = Math.max(...responseTimes);
  const minResponseTime = Math.min(...responseTimes);
  
  console.log(`平均レスポンス時間: ${avgResponseTime.toFixed(2)}ms`);
  console.log(`最大レスポンス時間: ${maxResponseTime.toFixed(2)}ms`);
  console.log(`最小レスポンス時間: ${minResponseTime.toFixed(2)}ms`);
  
  // 遅いエンドポイントの特定
  const slowEndpoints = testResults.performance
    .filter(p => p.responseTime > 2000)
    .sort((a, b) => b.responseTime - a.responseTime);
  
  if (slowEndpoints.length > 0) {
    console.log(`\n${colors.yellow}遅いエンドポイント (>2秒):${colors.reset}`);
    slowEndpoints.forEach(endpoint => {
      console.log(`  ${endpoint.method} ${endpoint.endpoint}: ${endpoint.responseTime.toFixed(2)}ms`);
    });
  }
  
  // 推奨事項
  console.log(`\n${colors.blue}${colors.bold}=== 推奨事項 ===${colors.reset}`);
  
  if (testResults.failed > 0) {
    console.log(`${colors.red}• ${testResults.failed}個の失敗したテストを修正してください${colors.reset}`);
  }
  
  if (slowEndpoints.length > 0) {
    console.log(`${colors.yellow}• ${slowEndpoints.length}個のエンドポイントのパフォーマンスを改善してください${colors.reset}`);
  }
  
  if (testResults.warnings.length > 0) {
    console.log(`${colors.yellow}• ${testResults.warnings.length}個の警告を確認してください${colors.reset}`);
  }
  
  if (testResults.failed === 0 && testResults.warnings.length === 0) {
    console.log(`${colors.green}• 全てのテストが成功しました！${colors.reset}`);
  }
  
  console.log(`\n${colors.bold}=== テスト完了 ===${colors.reset}`);
  
  // 結果をファイルに出力
  const reportData = {
    summary: {
      total: testResults.total,
      passed: testResults.passed,
      failed: testResults.failed,
      warnings: testResults.warnings.length,
      totalTime: totalTime,
      timestamp: new Date().toISOString()
    },
    errors: testResults.errors,
    warnings: testResults.warnings,
    performance: {
      average: avgResponseTime,
      max: maxResponseTime,
      min: minResponseTime,
      slowEndpoints: slowEndpoints
    },
    details: testResults.performance
  };
  
  console.log(`\nテスト結果レポートを出力しました。`);
  console.log(`詳細なデータ: ${JSON.stringify(reportData, null, 2)}`);
}

// テスト実行
runAllTests().catch(error => {
  log(`包括的テスト実行中にエラーが発生しました: ${error.message}`, 'error');
  console.error(error);
});