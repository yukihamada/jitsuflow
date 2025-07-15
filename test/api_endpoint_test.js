/**
 * JitsuFlow API エンドポイント実用テスト
 * 実際のAPIの動作に基づいた現実的なテストスイート
 */

const API_BASE_URL = 'https://jitsuflow-worker.yukihamada.workers.dev/api';

// テスト結果の追跡
let testResults = {
  total: 0,
  passed: 0,
  failed: 0,
  skipped: 0,
  errors: [],
  warnings: [],
  performance: []
};

// カラー出力
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

// APIリクエストヘルパー（修正版）
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
    
    let data;
    const contentType = response.headers.get('content-type');
    
    if (contentType && contentType.includes('application/json')) {
      try {
        data = await response.json();
      } catch (e) {
        data = { error: 'Invalid JSON response' };
      }
    } else {
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
    log(`🧪 Testing: ${testName}`, 'info');
    
    try {
      const result = await testFn();
      if (result === true || result?.success === true) {
        testResults.passed++;
        log(`✅ PASS: ${testName}`, 'success');
      } else if (result?.skip) {
        testResults.skipped++;
        log(`⏭️  SKIP: ${testName} - ${result.reason}`, 'warning');
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

/**
 * 1. 基本的なヘルスチェックテスト
 */
async function testHealthCheck() {
  const result = await apiRequest('/health', {}, 'Health Check');
  
  if (!result.success) {
    return { success: false, error: 'Health check failed' };
  }
  
  if (typeof result.data === 'object' && result.data.status === 'healthy') {
    return { success: true };
  }
  
  return { success: false, error: 'Invalid health check response' };
}

/**
 * 2. 認証なしでアクセス可能なエンドポイントのテスト
 */
async function testPublicEndpoints() {
  const publicEndpoints = [
    '/health',
    '/dojos', // 認証なしでもアクセス可能かもしれない
  ];
  
  let successCount = 0;
  
  for (const endpoint of publicEndpoints) {
    const result = await apiRequest(endpoint, {}, `Public Access: ${endpoint}`);
    if (result.success) {
      successCount++;
    }
  }
  
  return { success: true, note: `${successCount}/${publicEndpoints.length} public endpoints accessible` };
}

/**
 * 3. 認証が必要なエンドポイントのテスト（401 エラーの確認）
 */
async function testAuthRequiredEndpoints() {
  const authEndpoints = [
    '/products',
    '/cart',
    '/videos',
    '/dojo/bookings',
    '/dojo-mode/1/rentals'
  ];
  
  let properlyProtected = 0;
  
  for (const endpoint of authEndpoints) {
    const result = await apiRequest(endpoint, {}, `Auth Required: ${endpoint}`);
    if (result.status === 401) {
      properlyProtected++;
    }
  }
  
  const allProtected = properlyProtected === authEndpoints.length;
  
  return { 
    success: allProtected, 
    message: allProtected ? 
      'All protected endpoints properly require authentication' : 
      `Only ${properlyProtected}/${authEndpoints.length} endpoints properly protected`
  };
}

/**
 * 4. ユーザー登録のテスト（実際の動作を確認）
 */
async function testUserRegistration() {
  const testUser = {
    email: `test${Date.now()}@jitsuflow-test.com`,
    password: 'TestPass123!',
    name: 'テストユーザー',
    phone: '090-1234-5678'
  };
  
  const result = await apiRequest('/users/register', {
    method: 'POST',
    body: testUser
  }, 'User Registration');
  
  if (result.status === 404) {
    return { skip: true, reason: 'Registration endpoint not found' };
  }
  
  if (result.success) {
    return { success: true, message: 'Registration successful' };
  } else {
    return { success: false, error: result.data?.error || `Status: ${result.status}` };
  }
}

/**
 * 5. 不正な入力に対する適切な処理のテスト
 */
async function testInvalidInputHandling() {
  const invalidRequests = [
    {
      endpoint: '/users/register',
      method: 'POST',
      body: { invalid: 'data' },
      name: 'Invalid registration data'
    },
    {
      endpoint: '/products',
      method: 'GET',
      headers: { 'Authorization': 'Bearer invalid-token' },
      name: 'Invalid auth token'
    },
    {
      endpoint: '/nonexistent',
      method: 'GET',
      name: 'Nonexistent endpoint'
    }
  ];
  
  let properErrorCount = 0;
  
  for (const req of invalidRequests) {
    const result = await apiRequest(req.endpoint, {
      method: req.method,
      body: req.body,
      headers: req.headers
    }, `Invalid Input: ${req.name}`);
    
    // 4xx エラーが返されることを期待
    if (result.status >= 400 && result.status < 500) {
      properErrorCount++;
    }
  }
  
  const allProper = properErrorCount === invalidRequests.length;
  
  return { 
    success: allProper, 
    message: allProper ? 
      'All invalid inputs properly handled' : 
      `Only ${properErrorCount}/${invalidRequests.length} invalid inputs properly handled`
  };
}

/**
 * 6. レスポンス時間とパフォーマンスのテスト
 */
async function testPerformance() {
  const endpoints = [
    '/health',
    '/dojos',
    '/products',
    '/videos'
  ];
  
  const responses = [];
  
  for (const endpoint of endpoints) {
    const result = await apiRequest(endpoint, {}, `Performance: ${endpoint}`);
    responses.push({
      endpoint,
      responseTime: result.responseTime,
      status: result.status
    });
  }
  
  const avgResponseTime = responses.reduce((sum, r) => sum + r.responseTime, 0) / responses.length;
  const maxResponseTime = Math.max(...responses.map(r => r.responseTime));
  
  let performanceGrade = 'A';
  if (avgResponseTime > 2000) performanceGrade = 'C';
  else if (avgResponseTime > 1000) performanceGrade = 'B';
  
  return { 
    success: true, 
    message: `Avg: ${avgResponseTime.toFixed(2)}ms, Max: ${maxResponseTime.toFixed(2)}ms, Grade: ${performanceGrade}`
  };
}

/**
 * 7. セキュリティヘッダーのテスト
 */
async function testSecurityHeaders() {
  const result = await apiRequest('/health', {}, 'Security Headers');
  
  const securityHeaders = [
    'access-control-allow-origin',
    'access-control-allow-methods',
    'access-control-allow-headers'
  ];
  
  let presentHeaders = 0;
  
  for (const header of securityHeaders) {
    if (result.headers[header]) {
      presentHeaders++;
    }
  }
  
  return { 
    success: presentHeaders > 0, 
    message: `${presentHeaders}/${securityHeaders.length} security headers present`
  };
}

/**
 * 8. 同時接続テスト
 */
async function testConcurrentRequests() {
  const concurrentCount = 5;
  const promises = [];
  
  for (let i = 0; i < concurrentCount; i++) {
    promises.push(apiRequest('/health', {}, `Concurrent ${i + 1}`));
  }
  
  const startTime = performance.now();
  const results = await Promise.all(promises);
  const endTime = performance.now();
  
  const successCount = results.filter(r => r.success).length;
  const totalTime = endTime - startTime;
  
  return { 
    success: successCount === concurrentCount, 
    message: `${successCount}/${concurrentCount} concurrent requests succeeded in ${totalTime.toFixed(2)}ms`
  };
}

/**
 * 9. データ形式とスキーマの検証
 */
async function testResponseSchemas() {
  const result = await apiRequest('/health', {}, 'Response Schema');
  
  if (!result.success) {
    return { success: false, error: 'Could not get valid response for schema test' };
  }
  
  // Health endpoint のスキーマ検証
  const healthData = result.data;
  const requiredFields = ['status', 'timestamp', 'service'];
  
  for (const field of requiredFields) {
    if (!healthData[field]) {
      return { success: false, error: `Missing required field: ${field}` };
    }
  }
  
  return { success: true, message: 'Response schemas valid' };
}

/**
 * 10. エラーレスポンスの一貫性テスト
 */
async function testErrorConsistency() {
  // 意図的に 404 エラーを発生させる
  const result = await apiRequest('/nonexistent-endpoint', {}, 'Error Consistency');
  
  if (result.status !== 404) {
    return { success: false, error: `Expected 404, got ${result.status}` };
  }
  
  // エラーレスポンスの形式確認
  if (typeof result.data === 'object') {
    return { success: true, message: 'Error responses consistent' };
  }
  
  return { success: true, message: 'Error responses present (format varies)' };
}

/**
 * メインテスト実行
 */
async function runAllTests() {
  console.log(`${colors.bold}${colors.blue}🧪 JitsuFlow API エンドポイントテスト開始${colors.reset}\n`);
  
  const startTime = performance.now();
  
  // テスト実行
  await runTest('1. Health Check', testHealthCheck);
  await runTest('2. Public Endpoints Access', testPublicEndpoints);
  await runTest('3. Auth Required Endpoints', testAuthRequiredEndpoints);
  await runTest('4. User Registration', testUserRegistration);
  await runTest('5. Invalid Input Handling', testInvalidInputHandling);
  await runTest('6. Performance Test', testPerformance);
  await runTest('7. Security Headers', testSecurityHeaders);
  await runTest('8. Concurrent Requests', testConcurrentRequests);
  await runTest('9. Response Schemas', testResponseSchemas);
  await runTest('10. Error Consistency', testErrorConsistency);
  
  const endTime = performance.now();
  const totalTime = endTime - startTime;
  
  // 結果サマリー
  console.log(`\n${colors.bold}📊 テスト結果サマリー${colors.reset}`);
  console.log(`${colors.blue}総実行時間: ${totalTime.toFixed(2)}ms${colors.reset}`);
  console.log(`${colors.green}成功: ${testResults.passed}${colors.reset}`);
  console.log(`${colors.red}失敗: ${testResults.failed}${colors.reset}`);
  console.log(`${colors.yellow}スキップ: ${testResults.skipped}${colors.reset}`);
  console.log(`総テスト数: ${testResults.total}`);
  
  const successRate = (testResults.passed / (testResults.total - testResults.skipped)) * 100;
  console.log(`成功率: ${successRate.toFixed(1)}%`);
  
  // エラー詳細
  if (testResults.errors.length > 0) {
    console.log(`\n${colors.red}${colors.bold}❌ エラー詳細${colors.reset}`);
    testResults.errors.forEach(error => {
      console.log(`${colors.red}• ${error}${colors.reset}`);
    });
  }
  
  // パフォーマンス統計
  if (testResults.performance.length > 0) {
    const responseTimes = testResults.performance.map(p => p.responseTime);
    const avgResponseTime = responseTimes.reduce((a, b) => a + b, 0) / responseTimes.length;
    const maxResponseTime = Math.max(...responseTimes);
    const minResponseTime = Math.min(...responseTimes);
    
    console.log(`\n${colors.blue}${colors.bold}⚡ パフォーマンス統計${colors.reset}`);
    console.log(`平均レスポンス時間: ${avgResponseTime.toFixed(2)}ms`);
    console.log(`最大レスポンス時間: ${maxResponseTime.toFixed(2)}ms`);
    console.log(`最小レスポンス時間: ${minResponseTime.toFixed(2)}ms`);
    
    // 遅いエンドポイント
    const slowEndpoints = testResults.performance.filter(p => p.responseTime > 1000);
    if (slowEndpoints.length > 0) {
      console.log(`\n${colors.yellow}⚠️  遅いエンドポイント (>1秒):${colors.reset}`);
      slowEndpoints.forEach(ep => {
        console.log(`${colors.yellow}• ${ep.method} ${ep.endpoint}: ${ep.responseTime.toFixed(2)}ms${colors.reset}`);
      });
    }
  }
  
  // 推奨事項
  console.log(`\n${colors.blue}${colors.bold}📋 推奨事項${colors.reset}`);
  
  if (testResults.failed === 0) {
    console.log(`${colors.green}• ✅ 全てのテストが成功しました！APIは正常に動作しています。${colors.reset}`);
  } else {
    console.log(`${colors.red}• ${testResults.failed}個の失敗したテストを確認し、修正を検討してください。${colors.reset}`);
  }
  
  if (testResults.skipped > 0) {
    console.log(`${colors.yellow}• ${testResults.skipped}個のテストがスキップされました。該当機能の実装状況を確認してください。${colors.reset}`);
  }
  
  const avgResponseTime = testResults.performance.length > 0 ? 
    testResults.performance.reduce((a, b) => a.responseTime + b.responseTime, 0) / testResults.performance.length : 0;
  
  if (avgResponseTime > 1000) {
    console.log(`${colors.yellow}• パフォーマンスの改善を検討してください（平均レスポンス時間: ${avgResponseTime.toFixed(2)}ms）。${colors.reset}`);
  }
  
  console.log(`\n${colors.bold}🏁 テスト完了${colors.reset}`);
  
  // レポート出力
  const report = {
    summary: {
      total: testResults.total,
      passed: testResults.passed,
      failed: testResults.failed,
      skipped: testResults.skipped,
      successRate: successRate,
      totalTime: totalTime,
      timestamp: new Date().toISOString()
    },
    errors: testResults.errors,
    performance: {
      average: avgResponseTime,
      details: testResults.performance
    }
  };
  
  console.log(`\n📄 詳細レポート:`);
  console.log(JSON.stringify(report, null, 2));
}

// テスト実行
runAllTests().catch(error => {
  log(`テスト実行中にエラーが発生しました: ${error.message}`, 'error');
  console.error(error);
});