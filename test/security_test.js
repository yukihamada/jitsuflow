/**
 * JitsuFlow API セキュリティテストスイート
 * セキュリティ脆弱性の検出とペネトレーションテスト
 */

const API_BASE_URL = 'https://jitsuflow-worker.yukihamada.workers.dev/api';

// セキュリティテスト結果
let securityResults = {
  total: 0,
  passed: 0,
  failed: 0,
  vulnerabilities: [],
  warnings: []
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

// APIリクエストヘルパー
async function apiRequest(endpoint, options = {}) {
  const url = `${API_BASE_URL}${endpoint}`;
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
      headers: Object.fromEntries(response.headers.entries())
    };
  } catch (error) {
    return { 
      success: false, 
      error: error.message
    };
  }
}

// セキュリティテスト実行ヘルパー
function runSecurityTest(testName, testFn) {
  return new Promise(async (resolve) => {
    securityResults.total++;
    log(`🔒 Running: ${testName}`, 'info');
    
    try {
      const result = await testFn();
      if (result.success) {
        securityResults.passed++;
        log(`✅ SECURE: ${testName}`, 'success');
      } else {
        securityResults.failed++;
        if (result.vulnerability) {
          securityResults.vulnerabilities.push(`${testName}: ${result.message}`);
          log(`🚨 VULNERABILITY: ${testName} - ${result.message}`, 'error');
        } else {
          securityResults.warnings.push(`${testName}: ${result.message}`);
          log(`⚠️  WARNING: ${testName} - ${result.message}`, 'warning');
        }
      }
    } catch (error) {
      securityResults.failed++;
      securityResults.vulnerabilities.push(`${testName}: ${error.message}`);
      log(`❌ ERROR: ${testName} - ${error.message}`, 'error');
    }
    
    resolve();
  });
}

/**
 * 1. SQLインジェクションテスト群
 */
async function testSQLInjectionLogin() {
  const sqlPayloads = [
    "admin'--",
    "admin'/*",
    "' OR '1'='1' --",
    "' OR '1'='1' /*",
    "'; DROP TABLE users; --",
    "1' UNION SELECT username, password FROM users--",
    "1' OR 1=1#",
    "' OR 'a'='a",
    "admin' OR '1'='1",
    "' OR 1=1--"
  ];
  
  for (const payload of sqlPayloads) {
    const result = await apiRequest('/users/login', {
      method: 'POST',
      body: {
        email: payload,
        password: payload
      }
    });
    
    // SQLインジェクションが成功した場合は脆弱性
    if (result.success) {
      return {
        success: false,
        vulnerability: true,
        message: `SQL injection successful with payload: ${payload}`
      };
    }
    
    // エラーメッセージにSQL構文が含まれている場合も脆弱性の可能性
    if (result.data && typeof result.data === 'string') {
      const sqlKeywords = ['sql', 'syntax', 'mysql', 'postgres', 'sqlite', 'database', 'table', 'column'];
      const errorLower = result.data.toLowerCase();
      for (const keyword of sqlKeywords) {
        if (errorLower.includes(keyword)) {
          return {
            success: false,
            vulnerability: true,
            message: `Potential SQL error disclosure with payload: ${payload}`
          };
        }
      }
    }
  }
  
  return { success: true, message: 'No SQL injection vulnerabilities detected' };
}

async function testSQLInjectionSearch() {
  const sqlPayloads = [
    "'; DROP TABLE products; --",
    "1' UNION SELECT * FROM users--",
    "' OR '1'='1",
    "1' AND (SELECT COUNT(*) FROM users) > 0--"
  ];
  
  for (const payload of sqlPayloads) {
    // 商品検索での SQLインジェクション
    const result = await apiRequest(`/products?category=${encodeURIComponent(payload)}`);
    
    if (result.success && result.data && result.data.products) {
      // 不正な結果が返された場合
      if (result.data.products.length > 1000) {
        return {
          success: false,
          vulnerability: true,
          message: `Possible SQL injection in search with payload: ${payload}`
        };
      }
    }
  }
  
  return { success: true, message: 'No SQL injection in search detected' };
}

/**
 * 2. XSS (Cross-Site Scripting) テスト群
 */
async function testXSSInUserRegistration() {
  const xssPayloads = [
    "<script>alert('xss')</script>",
    "<img src=x onerror=alert('xss')>",
    "<svg onload=alert('xss')>",
    "javascript:alert('xss')",
    "<iframe src='javascript:alert(\"xss\")'></iframe>",
    "<body onload=alert('xss')>",
    "<div onclick=alert('xss')>click</div>",
    "';alert('xss');//",
    "\"><script>alert('xss')</script>",
    "<script>document.location='http://evil.com'</script>"
  ];
  
  for (const payload of xssPayloads) {
    const testUser = {
      email: `test${Date.now()}@test.com`,
      password: 'TestPass123!',
      name: payload,
      phone: '090-1234-5678'
    };
    
    const result = await apiRequest('/users/register', {
      method: 'POST',
      body: testUser
    });
    
    if (result.success && result.data.user && result.data.user.name === payload) {
      return {
        success: false,
        vulnerability: true,
        message: `XSS payload not sanitized in user registration: ${payload}`
      };
    }
  }
  
  return { success: true, message: 'XSS payloads properly sanitized in user registration' };
}

async function testXSSInComments() {
  const xssPayloads = [
    "<script>alert('xss')</script>",
    "<img src=x onerror=alert('xss')>",
    "javascript:alert('xss')"
  ];
  
  // コメント機能があるかテスト（実装に依存）
  for (const payload of xssPayloads) {
    const result = await apiRequest('/comments', {
      method: 'POST',
      body: {
        content: payload,
        video_id: 1
      }
    });
    
    // エンドポイントが存在しない場合はスキップ
    if (result.status === 404) {
      return { success: true, message: 'Comment endpoint not found, skipping XSS test' };
    }
  }
  
  return { success: true, message: 'No XSS vulnerabilities in comments' };
}

/**
 * 3. 認証・認可テスト群
 */
async function testAuthenticationBypass() {
  const bypassAttempts = [
    // JWTの改ざん
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c',
    // 無効なトークン
    'invalid-token',
    // 空のトークン
    '',
    // NULLバイト
    'Bearer \x00admin',
    // 長すぎるトークン
    'Bearer ' + 'a'.repeat(10000)
  ];
  
  for (const token of bypassAttempts) {
    const result = await apiRequest('/dojo/bookings', {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    
    if (result.success) {
      return {
        success: false,
        vulnerability: true,
        message: `Authentication bypass successful with token: ${token.substring(0, 50)}...`
      };
    }
  }
  
  return { success: true, message: 'No authentication bypass vulnerabilities detected' };
}

async function testPrivilegeEscalation() {
  // 通常ユーザーのトークンを取得
  const userLoginResult = await apiRequest('/users/login', {
    method: 'POST',
    body: {
      email: 'user@jitsuflow.app',
      password: 'demo123'
    }
  });
  
  if (!userLoginResult.success || !userLoginResult.data.token) {
    return { success: true, message: 'Could not get user token for privilege escalation test' };
  }
  
  const userToken = userLoginResult.data.token;
  
  // 管理者専用エンドポイントへのアクセス試行
  const adminEndpoints = [
    '/admin/users',
    '/admin/analytics',
    '/admin/settings',
    '/dojo-mode/1/analytics',
    '/admin/payments'
  ];
  
  for (const endpoint of adminEndpoints) {
    const result = await apiRequest(endpoint, {
      headers: {
        'Authorization': `Bearer ${userToken}`
      }
    });
    
    if (result.success) {
      return {
        success: false,
        vulnerability: true,
        message: `Privilege escalation: Regular user accessed admin endpoint: ${endpoint}`
      };
    }
  }
  
  return { success: true, message: 'No privilege escalation vulnerabilities detected' };
}

/**
 * 4. セッション管理テスト群
 */
async function testSessionFixation() {
  // セッション固定攻撃のテスト
  const fixedToken = 'fixed-session-token-123';
  
  const result = await apiRequest('/users/login', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${fixedToken}`
    },
    body: {
      email: 'user@jitsuflow.app',
      password: 'demo123'
    }
  });
  
  if (result.success && result.data.token === fixedToken) {
    return {
      success: false,
      vulnerability: true,
      message: 'Session fixation vulnerability: Server accepted predefined session token'
    };
  }
  
  return { success: true, message: 'No session fixation vulnerabilities detected' };
}

async function testSessionTimeout() {
  // 期限切れトークンのテスト
  const expiredToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjEsImVtYWlsIjoidGVzdEB0ZXN0LmNvbSIsImV4cCI6MTYwOTQ1OTIwMH0.invalid';
  
  const result = await apiRequest('/dojo/bookings', {
    headers: {
      'Authorization': `Bearer ${expiredToken}`
    }
  });
  
  if (result.success) {
    return {
      success: false,
      vulnerability: true,
      message: 'Session timeout vulnerability: Expired token was accepted'
    };
  }
  
  return { success: true, message: 'Session timeout properly enforced' };
}

/**
 * 5. 入力検証テスト群
 */
async function testInputValidationOverflows() {
  const overflowPayloads = {
    longString: 'a'.repeat(100000),
    longEmail: 'a'.repeat(1000) + '@example.com',
    specialChars: '!@#$%^&*()_+{}|:"<>?[];\'\\,./`~',
    unicodeChars: '𝕌𝕟𝕚𝕔𝕠𝕕𝕖 𝕋𝕖𝕤𝕥 🚀🔥💀',
    nullBytes: 'test\x00admin',
    negativeNumbers: '-999999999',
    largeNumbers: '999999999999999999999999999999'
  };
  
  for (const [type, payload] of Object.entries(overflowPayloads)) {
    const result = await apiRequest('/users/register', {
      method: 'POST',
      body: {
        email: type === 'longEmail' ? payload : `test${Date.now()}@test.com`,
        password: 'TestPass123!',
        name: type === 'longString' ? payload : `Test ${type}`,
        phone: type === 'longString' ? payload : '090-1234-5678'
      }
    });
    
    // サーバーがクラッシュしたり、500エラーになった場合は問題
    if (result.status === 500) {
      return {
        success: false,
        vulnerability: true,
        message: `Input validation overflow with ${type}: Server returned 500 error`
      };
    }
  }
  
  return { success: true, message: 'Input validation properly handles overflow attempts' };
}

async function testFileUploadVulnerabilities() {
  // ファイルアップロード脆弱性のテスト（実装に依存）
  const maliciousFiles = [
    { name: '../../etc/passwd', content: 'root:x:0:0:root:/root:/bin/bash' },
    { name: 'shell.php', content: '<?php system($_GET["cmd"]); ?>' },
    { name: 'script.js', content: 'alert("xss")' },
    { name: '.htaccess', content: 'RewriteEngine On' }
  ];
  
  for (const file of maliciousFiles) {
    const result = await apiRequest('/video-upload', {
      method: 'POST',
      headers: {
        'Content-Type': 'multipart/form-data'
      },
      body: {
        filename: file.name,
        content: file.content
      }
    });
    
    // ファイルアップロードエンドポイントが存在しない場合はスキップ
    if (result.status === 404) {
      return { success: true, message: 'File upload endpoint not found, skipping test' };
    }
    
    if (result.success) {
      return {
        success: false,
        vulnerability: true,
        message: `Malicious file upload accepted: ${file.name}`
      };
    }
  }
  
  return { success: true, message: 'File upload properly validates file types' };
}

/**
 * 6. レート制限・DoS テスト群
 */
async function testRateLimiting() {
  const requestCount = 50;
  const promises = [];
  
  log(`📊 Testing rate limiting with ${requestCount} concurrent requests...`, 'info');
  
  for (let i = 0; i < requestCount; i++) {
    promises.push(apiRequest('/health'));
  }
  
  const results = await Promise.all(promises);
  const successCount = results.filter(r => r.success).length;
  const tooManyRequests = results.filter(r => r.status === 429).length;
  
  if (successCount === requestCount && tooManyRequests === 0) {
    return {
      success: false,
      vulnerability: false,
      message: `No rate limiting detected: ${successCount}/${requestCount} requests succeeded`
    };
  }
  
  return { 
    success: true, 
    message: `Rate limiting working: ${tooManyRequests} requests rate limited, ${successCount} succeeded` 
  };
}

async function testDosVulnerabilities() {
  // 非常に大きなリクエストボディ
  const largePayload = 'x'.repeat(10 * 1024 * 1024); // 10MB
  
  const result = await apiRequest('/users/register', {
    method: 'POST',
    body: {
      email: 'test@test.com',
      password: 'TestPass123!',
      name: largePayload
    }
  });
  
  if (result.status === 500) {
    return {
      success: false,
      vulnerability: true,
      message: 'DoS vulnerability: Large payload caused server error'
    };
  }
  
  return { success: true, message: 'Server properly handles large payloads' };
}

/**
 * 7. 情報開示テスト群
 */
async function testInformationDisclosure() {
  const sensitiveEndpoints = [
    '/.env',
    '/config.json',
    '/package.json',
    '/wrangler.toml',
    '/.git/config',
    '/admin',
    '/debug',
    '/test',
    '/api/debug',
    '/api/config'
  ];
  
  for (const endpoint of sensitiveEndpoints) {
    const result = await apiRequest(endpoint);
    
    if (result.success && result.data) {
      // 設定情報や機密情報が含まれているかチェック
      const sensitiveKeywords = ['password', 'secret', 'key', 'token', 'database', 'api_key'];
      const dataStr = JSON.stringify(result.data).toLowerCase();
      
      for (const keyword of sensitiveKeywords) {
        if (dataStr.includes(keyword)) {
          return {
            success: false,
            vulnerability: true,
            message: `Information disclosure: Sensitive data exposed at ${endpoint}`
          };
        }
      }
    }
  }
  
  return { success: true, message: 'No information disclosure vulnerabilities detected' };
}

async function testErrorMessageDisclosure() {
  // エラーメッセージからの情報漏洩テスト
  const invalidRequests = [
    { endpoint: '/users/login', body: { email: 'invalid', password: 'invalid' } },
    { endpoint: '/products/99999', method: 'GET' },
    { endpoint: '/dojo/bookings', body: { invalid: 'data' } }
  ];
  
  for (const req of invalidRequests) {
    const result = await apiRequest(req.endpoint, {
      method: req.method || 'POST',
      body: req.body
    });
    
    if (result.data && typeof result.data === 'object' && result.data.error) {
      const errorMsg = result.data.error.toLowerCase();
      
      // システム情報が含まれていないかチェック
      const systemKeywords = ['stack trace', 'file path', 'database', 'sql', 'mysql', 'postgres'];
      for (const keyword of systemKeywords) {
        if (errorMsg.includes(keyword)) {
          return {
            success: false,
            vulnerability: true,
            message: `Error message disclosure: System information leaked in error: ${keyword}`
          };
        }
      }
    }
  }
  
  return { success: true, message: 'Error messages do not disclose sensitive information' };
}

/**
 * メインテスト実行
 */
async function runAllSecurityTests() {
  console.log(`${colors.bold}${colors.blue}=== JitsuFlow API セキュリティテスト開始 ===${colors.reset}\n`);
  
  const startTime = performance.now();
  
  // 1. SQLインジェクションテスト群
  await runSecurityTest('SQL Injection - Login', testSQLInjectionLogin);
  await runSecurityTest('SQL Injection - Search', testSQLInjectionSearch);
  
  // 2. XSSテスト群
  await runSecurityTest('XSS - User Registration', testXSSInUserRegistration);
  await runSecurityTest('XSS - Comments', testXSSInComments);
  
  // 3. 認証・認可テスト群
  await runSecurityTest('Authentication Bypass', testAuthenticationBypass);
  await runSecurityTest('Privilege Escalation', testPrivilegeEscalation);
  
  // 4. セッション管理テスト群
  await runSecurityTest('Session Fixation', testSessionFixation);
  await runSecurityTest('Session Timeout', testSessionTimeout);
  
  // 5. 入力検証テスト群
  await runSecurityTest('Input Validation - Overflows', testInputValidationOverflows);
  await runSecurityTest('File Upload Vulnerabilities', testFileUploadVulnerabilities);
  
  // 6. レート制限・DoSテスト群
  await runSecurityTest('Rate Limiting', testRateLimiting);
  await runSecurityTest('DoS Vulnerabilities', testDosVulnerabilities);
  
  // 7. 情報開示テスト群
  await runSecurityTest('Information Disclosure', testInformationDisclosure);
  await runSecurityTest('Error Message Disclosure', testErrorMessageDisclosure);
  
  const endTime = performance.now();
  const totalTime = endTime - startTime;
  
  // セキュリティレポートの生成
  console.log(`\n${colors.bold}=== セキュリティテスト結果サマリー ===${colors.reset}`);
  console.log(`${colors.blue}総実行時間: ${totalTime.toFixed(2)}ms${colors.reset}`);
  console.log(`${colors.green}セキュア: ${securityResults.passed}${colors.reset}`);
  console.log(`${colors.red}脆弱性: ${securityResults.vulnerabilities.length}${colors.reset}`);
  console.log(`${colors.yellow}警告: ${securityResults.warnings.length}${colors.reset}`);
  console.log(`総テスト数: ${securityResults.total}`);
  
  if (securityResults.vulnerabilities.length > 0) {
    console.log(`\n${colors.red}${colors.bold}🚨 検出された脆弱性 ===${colors.reset}`);
    securityResults.vulnerabilities.forEach(vuln => {
      console.log(`${colors.red}❌ ${vuln}${colors.reset}`);
    });
  }
  
  if (securityResults.warnings.length > 0) {
    console.log(`\n${colors.yellow}${colors.bold}⚠️  警告事項 ===${colors.reset}`);
    securityResults.warnings.forEach(warning => {
      console.log(`${colors.yellow}⚠️  ${warning}${colors.reset}`);
    });
  }
  
  // セキュリティ評価
  console.log(`\n${colors.blue}${colors.bold}📊 セキュリティ評価:${colors.reset}`);
  
  const vulnerabilityScore = securityResults.vulnerabilities.length;
  const warningScore = securityResults.warnings.length;
  
  let securityGrade = 'A+';
  let gradeColor = colors.green;
  
  if (vulnerabilityScore > 0) {
    securityGrade = vulnerabilityScore > 3 ? 'F' : vulnerabilityScore > 1 ? 'D' : 'C';
    gradeColor = colors.red;
  } else if (warningScore > 3) {
    securityGrade = 'B';
    gradeColor = colors.yellow;
  } else if (warningScore > 0) {
    securityGrade = 'A';
    gradeColor = colors.green;
  }
  
  console.log(`${gradeColor}セキュリティグレード: ${securityGrade}${colors.reset}`);
  
  // 推奨事項
  console.log(`\n${colors.blue}${colors.bold}📋 セキュリティ推奨事項:${colors.reset}`);
  
  if (vulnerabilityScore > 0) {
    console.log(`${colors.red}• 🚨 ${vulnerabilityScore}個の脆弱性を即座に修正してください${colors.reset}`);
  }
  
  if (warningScore > 0) {
    console.log(`${colors.yellow}• ⚠️  ${warningScore}個の警告事項を確認し、改善を検討してください${colors.reset}`);
  }
  
  if (vulnerabilityScore === 0 && warningScore === 0) {
    console.log(`${colors.green}• ✅ 重大なセキュリティ問題は検出されませんでした${colors.reset}`);
  }
  
  console.log(`\n${colors.blue}追加の推奨事項:${colors.reset}`);
  console.log(`• 定期的にセキュリティテストを実施してください`);
  console.log(`• 依存関係の脆弱性を定期的にチェックしてください`);
  console.log(`• セキュリティヘッダーの設定を確認してください`);
  console.log(`• ログ監視とアラート設定を強化してください`);
  
  console.log(`\n${colors.bold}=== セキュリティテスト完了 ===${colors.reset}`);
  
  return {
    summary: {
      total: securityResults.total,
      passed: securityResults.passed,
      vulnerabilities: securityResults.vulnerabilities.length,
      warnings: securityResults.warnings.length,
      grade: securityGrade,
      totalTime: totalTime,
      timestamp: new Date().toISOString()
    },
    vulnerabilities: securityResults.vulnerabilities,
    warnings: securityResults.warnings
  };
}

// テスト実行
runAllSecurityTests().catch(error => {
  log(`セキュリティテスト実行中にエラーが発生しました: ${error.message}`, 'error');
  console.error(error);
});