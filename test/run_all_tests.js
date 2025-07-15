#!/usr/bin/env node

/**
 * JitsuFlow API 統合テストランナー
 * 全てのAPIテストを実行し、統合レポートを生成
 */

const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

// カラー出力
const colors = {
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
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

// テスト結果を格納
const testResults = {
  comprehensive: null,
  security: null,
  performance: null,
  startTime: null,
  endTime: null,
  totalDuration: 0,
  overallStatus: 'pending'
};

// 外部プロセス実行ヘルパー
function runCommand(command, args = []) {
  return new Promise((resolve, reject) => {
    log(`🚀 実行中: ${command} ${args.join(' ')}`, 'info');
    
    const process = spawn(command, args, {
      stdio: 'pipe',
      cwd: path.dirname(__dirname)
    });
    
    let stdout = '';
    let stderr = '';
    
    process.stdout.on('data', (data) => {
      const output = data.toString();
      stdout += output;
      // リアルタイムで出力を表示
      process.stdout.write(output);
    });
    
    process.stderr.on('data', (data) => {
      const output = data.toString();
      stderr += output;
      process.stderr.write(output);
    });
    
    process.on('close', (code) => {
      if (code === 0) {
        resolve({ stdout, stderr, code });
      } else {
        reject(new Error(`Process exited with code ${code}\nSTDOUT: ${stdout}\nSTDERR: ${stderr}`));
      }
    });
    
    process.on('error', (error) => {
      reject(error);
    });
  });
}

// 個別テストの実行
async function runComprehensiveTest() {
  log('📋 包括的APIテスト開始', 'info');
  try {
    const result = await runCommand('node', ['test/comprehensive_api_test.js']);
    testResults.comprehensive = {
      status: 'completed',
      output: result.stdout,
      error: null
    };
    log('✅ 包括的APIテスト完了', 'success');
  } catch (error) {
    testResults.comprehensive = {
      status: 'failed',
      output: error.message,
      error: error.message
    };
    log('❌ 包括的APIテスト失敗', 'error');
  }
}

async function runSecurityTest() {
  log('🔒 セキュリティテスト開始', 'info');
  try {
    const result = await runCommand('node', ['test/security_test.js']);
    testResults.security = {
      status: 'completed',
      output: result.stdout,
      error: null
    };
    log('✅ セキュリティテスト完了', 'success');
  } catch (error) {
    testResults.security = {
      status: 'failed',
      output: error.message,
      error: error.message
    };
    log('❌ セキュリティテスト失敗', 'error');
  }
}

async function runPerformanceTest() {
  log('⚡ パフォーマンステスト開始', 'info');
  try {
    const result = await runCommand('node', ['test/performance_monitor.js', 'single']);
    testResults.performance = {
      status: 'completed',
      output: result.stdout,
      error: null
    };
    log('✅ パフォーマンステスト完了', 'success');
  } catch (error) {
    testResults.performance = {
      status: 'failed',
      output: error.message,
      error: error.message
    };
    log('❌ パフォーマンステスト失敗', 'error');
  }
}

// 結果解析
function parseTestResults() {
  const results = {
    comprehensive: { passed: 0, failed: 0, total: 0, errors: [], warnings: [] },
    security: { vulnerabilities: 0, warnings: 0, total: 0, grade: 'N/A' },
    performance: { average: 0, max: 0, min: 0, slowEndpoints: [] }
  };
  
  // 包括的テスト結果の解析
  if (testResults.comprehensive?.output) {
    const output = testResults.comprehensive.output;
    const passedMatch = output.match(/成功: (\d+)/);
    const failedMatch = output.match(/失敗: (\d+)/);
    const totalMatch = output.match(/総テスト数: (\d+)/);
    
    if (passedMatch) results.comprehensive.passed = parseInt(passedMatch[1]);
    if (failedMatch) results.comprehensive.failed = parseInt(failedMatch[1]);
    if (totalMatch) results.comprehensive.total = parseInt(totalMatch[1]);
    
    // エラーと警告の抽出
    const errorLines = output.split('\n').filter(line => line.includes('❌'));
    const warningLines = output.split('\n').filter(line => line.includes('⚠️'));
    results.comprehensive.errors = errorLines;
    results.comprehensive.warnings = warningLines;
  }
  
  // セキュリティテスト結果の解析
  if (testResults.security?.output) {
    const output = testResults.security.output;
    const vulnMatch = output.match(/脆弱性: (\d+)/);
    const warningMatch = output.match(/警告: (\d+)/);
    const gradeMatch = output.match(/セキュリティグレード: ([A-F][+]?)/);
    
    if (vulnMatch) results.security.vulnerabilities = parseInt(vulnMatch[1]);
    if (warningMatch) results.security.warnings = parseInt(warningMatch[1]);
    if (gradeMatch) results.security.grade = gradeMatch[1];
  }
  
  // パフォーマンステスト結果の解析
  if (testResults.performance?.output) {
    const output = testResults.performance.output;
    const avgMatch = output.match(/平均レスポンス時間: ([\d.]+)ms/);
    const maxMatch = output.match(/最大レスポンス時間: ([\d.]+)ms/);
    const minMatch = output.match(/最小レスポンス時間: ([\d.]+)ms/);
    
    if (avgMatch) results.performance.average = parseFloat(avgMatch[1]);
    if (maxMatch) results.performance.max = parseFloat(maxMatch[1]);
    if (minMatch) results.performance.min = parseFloat(minMatch[1]);
    
    // 遅いエンドポイントの抽出
    const slowLines = output.split('\n').filter(line => line.includes('遅いエンドポイント'));
    results.performance.slowEndpoints = slowLines;
  }
  
  return results;
}

// 統合レポート生成
function generateIntegratedReport(parsedResults) {
  const report = {
    summary: {
      timestamp: new Date().toISOString(),
      duration: testResults.totalDuration,
      overallStatus: testResults.overallStatus
    },
    comprehensive: parsedResults.comprehensive,
    security: parsedResults.security,
    performance: parsedResults.performance,
    recommendations: []
  };
  
  // 推奨事項の生成
  if (parsedResults.comprehensive.failed > 0) {
    report.recommendations.push({
      type: 'critical',
      category: 'functionality',
      message: `${parsedResults.comprehensive.failed}個のAPIテストが失敗しています。これらの問題を最優先で修正してください。`
    });
  }
  
  if (parsedResults.security.vulnerabilities > 0) {
    report.recommendations.push({
      type: 'critical',
      category: 'security',
      message: `${parsedResults.security.vulnerabilities}個のセキュリティ脆弱性が検出されました。即座に修正してください。`
    });
  }
  
  if (parsedResults.performance.average > 2000) {
    report.recommendations.push({
      type: 'warning',
      category: 'performance',
      message: `平均レスポンス時間が${parsedResults.performance.average.toFixed(2)}msです。パフォーマンスの改善を検討してください。`
    });
  }
  
  if (parsedResults.security.grade !== 'A+' && parsedResults.security.grade !== 'A') {
    report.recommendations.push({
      type: 'warning',
      category: 'security',
      message: `セキュリティグレードが${parsedResults.security.grade}です。セキュリティの強化を検討してください。`
    });
  }
  
  // 成功時のメッセージ
  if (parsedResults.comprehensive.failed === 0 && 
      parsedResults.security.vulnerabilities === 0 && 
      parsedResults.performance.average < 2000) {
    report.recommendations.push({
      type: 'success',
      category: 'overall',
      message: '🎉 全てのテストが成功しました！APIは正常に動作しています。'
    });
  }
  
  return report;
}

// レポート表示
function displayReport(report) {
  console.log(`\n${colors.bold}${colors.cyan}╔══════════════════════════════════════════════════════════════╗${colors.reset}`);
  console.log(`${colors.bold}${colors.cyan}║                    JitsuFlow API 統合テストレポート               ║${colors.reset}`);
  console.log(`${colors.bold}${colors.cyan}╚══════════════════════════════════════════════════════════════╝${colors.reset}\n`);
  
  // サマリー
  console.log(`${colors.bold}📊 テスト実行サマリー${colors.reset}`);
  console.log(`実行時刻: ${new Date(report.summary.timestamp).toLocaleString()}`);
  console.log(`実行時間: ${(report.summary.duration / 1000).toFixed(2)}秒`);
  console.log(`総合ステータス: ${report.summary.overallStatus === 'success' ? colors.green + '✅ 成功' : colors.red + '❌ 失敗'}${colors.reset}\n`);
  
  // 包括的テスト結果
  console.log(`${colors.bold}📋 包括的APIテスト結果${colors.reset}`);
  console.log(`成功: ${colors.green}${report.comprehensive.passed}${colors.reset}`);
  console.log(`失敗: ${colors.red}${report.comprehensive.failed}${colors.reset}`);
  console.log(`総テスト数: ${report.comprehensive.total}`);
  console.log(`成功率: ${report.comprehensive.total > 0 ? ((report.comprehensive.passed / report.comprehensive.total) * 100).toFixed(1) : 0}%\n`);
  
  // セキュリティテスト結果
  console.log(`${colors.bold}🔒 セキュリティテスト結果${colors.reset}`);
  console.log(`脆弱性: ${report.security.vulnerabilities > 0 ? colors.red : colors.green}${report.security.vulnerabilities}${colors.reset}`);
  console.log(`警告: ${report.security.warnings > 0 ? colors.yellow : colors.green}${report.security.warnings}${colors.reset}`);
  console.log(`セキュリティグレード: ${report.security.grade === 'A+' || report.security.grade === 'A' ? colors.green : colors.yellow}${report.security.grade}${colors.reset}\n`);
  
  // パフォーマンステスト結果
  console.log(`${colors.bold}⚡ パフォーマンステスト結果${colors.reset}`);
  console.log(`平均レスポンス時間: ${report.performance.average > 2000 ? colors.red : report.performance.average > 1000 ? colors.yellow : colors.green}${report.performance.average.toFixed(2)}ms${colors.reset}`);
  console.log(`最大レスポンス時間: ${report.performance.max.toFixed(2)}ms`);
  console.log(`最小レスポンス時間: ${report.performance.min.toFixed(2)}ms\n`);
  
  // 推奨事項
  if (report.recommendations.length > 0) {
    console.log(`${colors.bold}📋 推奨事項${colors.reset}`);
    report.recommendations.forEach(rec => {
      const icon = rec.type === 'critical' ? '🚨' : rec.type === 'warning' ? '⚠️' : '✅';
      const color = rec.type === 'critical' ? colors.red : rec.type === 'warning' ? colors.yellow : colors.green;
      console.log(`${color}${icon} ${rec.message}${colors.reset}`);
    });
    console.log('');
  }
  
  // 詳細情報へのリンク
  console.log(`${colors.bold}📄 詳細情報${colors.reset}`);
  console.log(`各テストの詳細な出力は個別のテストファイルを直接実行してご確認ください:`);
  console.log(`${colors.cyan}• npm run test:api:comprehensive${colors.reset} - 包括的APIテスト`);
  console.log(`${colors.cyan}• npm run test:security${colors.reset} - セキュリティテスト`);
  console.log(`${colors.cyan}• npm run test:performance${colors.reset} - パフォーマンステスト`);
  console.log('');
}

// JSONレポート保存
function saveJsonReport(report) {
  const reportPath = path.join(__dirname, 'test-report.json');
  try {
    fs.writeFileSync(reportPath, JSON.stringify(report, null, 2));
    log(`📄 詳細レポートを保存しました: ${reportPath}`, 'success');
  } catch (error) {
    log(`レポート保存に失敗しました: ${error.message}`, 'error');
  }
}

// メイン実行関数
async function runAllTests() {
  testResults.startTime = new Date();
  
  console.log(`${colors.bold}${colors.blue}🚀 JitsuFlow API 統合テスト開始${colors.reset}`);
  console.log(`開始時刻: ${testResults.startTime.toLocaleString()}\n`);
  
  try {
    // 各テストを順次実行
    await runComprehensiveTest();
    await runSecurityTest();
    await runPerformanceTest();
    
    testResults.endTime = new Date();
    testResults.totalDuration = testResults.endTime - testResults.startTime;
    
    // 結果解析
    const parsedResults = parseTestResults();
    
    // 総合ステータス判定
    const hasFailures = testResults.comprehensive?.status === 'failed' ||
                       testResults.security?.status === 'failed' ||
                       testResults.performance?.status === 'failed' ||
                       parsedResults.comprehensive.failed > 0 ||
                       parsedResults.security.vulnerabilities > 0;
    
    testResults.overallStatus = hasFailures ? 'failed' : 'success';
    
    // レポート生成と表示
    const report = generateIntegratedReport(parsedResults);
    displayReport(report);
    saveJsonReport(report);
    
    // 終了処理
    console.log(`${colors.bold}${colors.blue}🏁 JitsuFlow API 統合テスト完了${colors.reset}`);
    console.log(`終了時刻: ${testResults.endTime.toLocaleString()}`);
    console.log(`総実行時間: ${(testResults.totalDuration / 1000).toFixed(2)}秒\n`);
    
    // 終了コード設定
    if (testResults.overallStatus === 'success') {
      log('🎉 全てのテストが成功しました！', 'success');
      process.exit(0);
    } else {
      log('❌ 一部のテストで問題が検出されました。', 'error');
      process.exit(1);
    }
    
  } catch (error) {
    log(`統合テスト実行中にエラーが発生しました: ${error.message}`, 'error');
    process.exit(1);
  }
}

// コマンドライン引数の処理
const args = process.argv.slice(2);
if (args.includes('--help') || args.includes('-h')) {
  console.log('JitsuFlow API 統合テストランナー');
  console.log('');
  console.log('使用方法: node test/run_all_tests.js');
  console.log('');
  console.log('このスクリプトは以下のテストを順次実行します:');
  console.log('1. 包括的APIテスト - 全エンドポイントの機能テスト');
  console.log('2. セキュリティテスト - 脆弱性スキャン');
  console.log('3. パフォーマンステスト - レスポンス時間測定');
  console.log('');
  console.log('結果はコンソールに表示され、詳細レポートはtest-report.jsonに保存されます。');
  process.exit(0);
}

// テスト実行
runAllTests();