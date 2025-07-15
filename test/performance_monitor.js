/**
 * JitsuFlow API パフォーマンスモニタリングツール
 * 継続的なパフォーマンス測定とアラート
 */

const API_BASE_URL = 'https://jitsuflow-worker.yukihamada.workers.dev/api';

// パフォーマンス閾値
const PERFORMANCE_THRESHOLDS = {
  warning: 2000,  // 2秒
  critical: 5000, // 5秒
  timeout: 30000  // 30秒
};

// 監視対象エンドポイント
const ENDPOINTS_TO_MONITOR = [
  { path: '/health', method: 'GET', requiresAuth: false },
  { path: '/dojos', method: 'GET', requiresAuth: true },
  { path: '/products?limit=10', method: 'GET', requiresAuth: true },
  { path: '/videos', method: 'GET', requiresAuth: true },
  { path: '/cart', method: 'GET', requiresAuth: true },
  { path: '/dojo/bookings', method: 'GET', requiresAuth: true }
];

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

// 認証トークンの取得
async function getAuthToken() {
  try {
    const testUser = {
      email: 'user@jitsuflow.app',
      password: 'demo123'
    };
    
    const response = await fetch(`${API_BASE_URL}/users/login`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(testUser)
    });
    
    if (!response.ok) {
      throw new Error(`Login failed: ${response.status}`);
    }
    
    const data = await response.json();
    return data.token;
  } catch (error) {
    log(`認証トークン取得失敗: ${error.message}`, 'error');
    return null;
  }
}

// 単一エンドポイントの監視
async function monitorEndpoint(endpoint, authToken = null) {
  const startTime = performance.now();
  const timeout = setTimeout(() => {
    log(`⏰ TIMEOUT: ${endpoint.method} ${endpoint.path} (>${PERFORMANCE_THRESHOLDS.timeout}ms)`, 'error');
  }, PERFORMANCE_THRESHOLDS.timeout);
  
  try {
    const headers = {
      'Content-Type': 'application/json'
    };
    
    if (endpoint.requiresAuth && authToken) {
      headers['Authorization'] = `Bearer ${authToken}`;
    }
    
    const response = await fetch(`${API_BASE_URL}${endpoint.path}`, {
      method: endpoint.method,
      headers,
      signal: AbortSignal.timeout(PERFORMANCE_THRESHOLDS.timeout)
    });
    
    clearTimeout(timeout);
    const endTime = performance.now();
    const responseTime = endTime - startTime;
    
    const result = {
      endpoint: endpoint.path,
      method: endpoint.method,
      status: response.status,
      responseTime: responseTime,
      success: response.ok,
      timestamp: new Date().toISOString()
    };
    
    // パフォーマンス評価
    let performanceLevel = 'good';
    let logType = 'success';
    
    if (responseTime > PERFORMANCE_THRESHOLDS.critical) {
      performanceLevel = 'critical';
      logType = 'error';
    } else if (responseTime > PERFORMANCE_THRESHOLDS.warning) {
      performanceLevel = 'warning';
      logType = 'warning';
    }
    
    const statusIcon = response.ok ? '✅' : '❌';
    const perfIcon = performanceLevel === 'critical' ? '🔴' : 
                    performanceLevel === 'warning' ? '🟡' : '🟢';
    
    log(`${statusIcon} ${perfIcon} ${endpoint.method} ${endpoint.path} - ${response.status} (${responseTime.toFixed(2)}ms)`, logType);
    
    return result;
    
  } catch (error) {
    clearTimeout(timeout);
    const endTime = performance.now();
    const responseTime = endTime - startTime;
    
    log(`❌ ERROR: ${endpoint.method} ${endpoint.path} - ${error.message} (${responseTime.toFixed(2)}ms)`, 'error');
    
    return {
      endpoint: endpoint.path,
      method: endpoint.method,
      status: 'ERROR',
      responseTime: responseTime,
      success: false,
      error: error.message,
      timestamp: new Date().toISOString()
    };
  }
}

// 全エンドポイントの監視
async function monitorAllEndpoints() {
  log('🔍 パフォーマンス監視開始', 'info');
  
  // 認証トークンの取得
  const authToken = await getAuthToken();
  if (!authToken) {
    log('認証トークンが取得できませんでした。認証が必要なエンドポイントはスキップされます。', 'warning');
  }
  
  const results = [];
  
  for (const endpoint of ENDPOINTS_TO_MONITOR) {
    if (endpoint.requiresAuth && !authToken) {
      log(`⏭️  SKIP: ${endpoint.method} ${endpoint.path} (認証が必要)`, 'warning');
      continue;
    }
    
    const result = await monitorEndpoint(endpoint, authToken);
    results.push(result);
    
    // リクエスト間の間隔
    await new Promise(resolve => setTimeout(resolve, 1000));
  }
  
  return results;
}

// 統計計算
function calculateStats(results) {
  const successfulResults = results.filter(r => r.success && typeof r.responseTime === 'number');
  
  if (successfulResults.length === 0) {
    return {
      count: 0,
      average: 0,
      min: 0,
      max: 0,
      successRate: 0
    };
  }
  
  const responseTimes = successfulResults.map(r => r.responseTime);
  const sum = responseTimes.reduce((a, b) => a + b, 0);
  
  return {
    count: results.length,
    successCount: successfulResults.length,
    average: sum / successfulResults.length,
    min: Math.min(...responseTimes),
    max: Math.max(...responseTimes),
    successRate: (successfulResults.length / results.length) * 100
  };
}

// レポート生成
function generateReport(results) {
  const stats = calculateStats(results);
  
  console.log(`\n${colors.bold}${colors.blue}=== パフォーマンス監視レポート ===${colors.reset}`);
  console.log(`実行時刻: ${new Date().toLocaleString()}`);
  console.log(`監視対象: ${stats.count} エンドポイント`);
  console.log(`成功率: ${stats.successRate.toFixed(1)}% (${stats.successCount}/${stats.count})`);
  
  if (stats.successCount > 0) {
    console.log(`平均レスポンス時間: ${stats.average.toFixed(2)}ms`);
    console.log(`最速レスポンス: ${stats.min.toFixed(2)}ms`);
    console.log(`最遅レスポンス: ${stats.max.toFixed(2)}ms`);
  }
  
  // アラート
  const criticalResults = results.filter(r => r.responseTime > PERFORMANCE_THRESHOLDS.critical);
  const warningResults = results.filter(r => r.responseTime > PERFORMANCE_THRESHOLDS.warning && r.responseTime <= PERFORMANCE_THRESHOLDS.critical);
  const errorResults = results.filter(r => !r.success);
  
  if (criticalResults.length > 0) {
    console.log(`\n${colors.red}${colors.bold}🔴 CRITICAL ALERTS (>${PERFORMANCE_THRESHOLDS.critical}ms):${colors.reset}`);
    criticalResults.forEach(r => {
      console.log(`${colors.red}  ${r.method} ${r.endpoint}: ${r.responseTime.toFixed(2)}ms${colors.reset}`);
    });
  }
  
  if (warningResults.length > 0) {
    console.log(`\n${colors.yellow}${colors.bold}🟡 WARNING ALERTS (>${PERFORMANCE_THRESHOLDS.warning}ms):${colors.reset}`);
    warningResults.forEach(r => {
      console.log(`${colors.yellow}  ${r.method} ${r.endpoint}: ${r.responseTime.toFixed(2)}ms${colors.reset}`);
    });
  }
  
  if (errorResults.length > 0) {
    console.log(`\n${colors.red}${colors.bold}❌ ERROR ALERTS:${colors.reset}`);
    errorResults.forEach(r => {
      console.log(`${colors.red}  ${r.method} ${r.endpoint}: ${r.error || r.status}${colors.reset}`);
    });
  }
  
  // 推奨事項
  console.log(`\n${colors.blue}${colors.bold}📋 推奨事項:${colors.reset}`);
  
  if (stats.successRate < 95) {
    console.log(`${colors.red}• 成功率が95%を下回っています (${stats.successRate.toFixed(1)}%)${colors.reset}`);
  }
  
  if (stats.average > PERFORMANCE_THRESHOLDS.warning) {
    console.log(`${colors.yellow}• 平均レスポンス時間が${PERFORMANCE_THRESHOLDS.warning}msを超えています${colors.reset}`);
  }
  
  if (criticalResults.length > 0) {
    console.log(`${colors.red}• ${criticalResults.length}個のエンドポイントが重大なパフォーマンス問題を抱えています${colors.reset}`);
  }
  
  if (errorResults.length === 0 && criticalResults.length === 0 && warningResults.length === 0) {
    console.log(`${colors.green}• 全てのエンドポイントが正常に動作しています！${colors.reset}`);
  }
  
  return {
    summary: stats,
    alerts: {
      critical: criticalResults.length,
      warning: warningResults.length,
      errors: errorResults.length
    },
    timestamp: new Date().toISOString(),
    results: results
  };
}

// 継続監視モード
async function continuousMonitoring(intervalMinutes = 5) {
  log(`🔄 継続監視モード開始 (間隔: ${intervalMinutes}分)`, 'info');
  
  while (true) {
    try {
      const results = await monitorAllEndpoints();
      const report = generateReport(results);
      
      // アラートがある場合は強調表示
      if (report.alerts.critical > 0) {
        log(`🚨 CRITICAL: ${report.alerts.critical}個の重大なパフォーマンス問題が検出されました`, 'error');
      }
      
      if (report.alerts.errors > 0) {
        log(`⚠️  WARNING: ${report.alerts.errors}個のエラーが検出されました`, 'warning');
      }
      
      // 次回実行まで待機
      const waitMs = intervalMinutes * 60 * 1000;
      log(`⏰ 次回監視まで ${intervalMinutes}分待機中...`, 'info');
      await new Promise(resolve => setTimeout(resolve, waitMs));
      
    } catch (error) {
      log(`監視中にエラーが発生しました: ${error.message}`, 'error');
      // エラーが発生しても継続
      await new Promise(resolve => setTimeout(resolve, 30000)); // 30秒待機
    }
  }
}

// 単発監視モード
async function singleMonitoring() {
  try {
    const results = await monitorAllEndpoints();
    generateReport(results);
  } catch (error) {
    log(`監視中にエラーが発生しました: ${error.message}`, 'error');
  }
}

// コマンドライン引数の処理
const args = process.argv.slice(2);
const mode = args[0] || 'single';

if (mode === 'continuous') {
  const interval = parseInt(args[1]) || 5;
  continuousMonitoring(interval);
} else if (mode === 'single') {
  singleMonitoring();
} else {
  console.log('使用方法:');
  console.log('  node performance_monitor.js single           # 単発監視');
  console.log('  node performance_monitor.js continuous [分]   # 継続監視 (デフォルト: 5分間隔)');
  console.log('');
  console.log('例:');
  console.log('  node performance_monitor.js continuous 10    # 10分間隔で継続監視');
}