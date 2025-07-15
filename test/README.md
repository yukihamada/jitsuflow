# JitsuFlow API テストスイート

## 概要

JitsuFlow APIの包括的なテストスイートです。機能テスト、セキュリティテスト、パフォーマンステストを提供し、APIの品質と安全性を確保します。

## テストファイル構成

### 🧪 テストファイル

| ファイル | 目的 | 実行コマンド |
|---------|------|-------------|
| `comprehensive_api_test.js` | 全エンドポイントの包括的テスト | `npm run test:api:comprehensive` |
| `security_test.js` | セキュリティ脆弱性テスト | `npm run test:security` |
| `performance_monitor.js` | パフォーマンス監視 | `npm run test:performance` |
| `run_all_tests.js` | 統合テストランナー | `npm run test:all` |
| `api_test.js` | 基本的なAPIテスト（既存） | `npm run test:api` |

### 📋 テスト対象エンドポイント

#### 認証・ユーザー管理
- `POST /api/users/register` - ユーザー登録
- `POST /api/users/login` - ユーザーログイン

#### 道場管理
- `GET /api/dojos` - 道場一覧取得

#### 商品・カート管理
- `GET /api/products` - 商品一覧取得
- `POST /api/cart/add` - カートに商品追加
- `GET /api/cart` - カート内容取得

#### 予約システム
- `POST /api/dojo/bookings` - 予約作成
- `GET /api/dojo/bookings` - 予約一覧取得

#### ビデオコンテンツ
- `GET /api/videos` - ビデオ一覧取得

#### レンタルシステム
- `GET /api/dojo-mode/{dojoId}/rentals` - レンタル品一覧
- `POST /api/rentals/{rentalId}/rent` - レンタル開始

## テストカテゴリ

### 🧪 包括的APIテスト (`comprehensive_api_test.js`)

**成功ケース**
- 正常なリクエストでの適切なレスポンス
- 認証済みユーザーのリソースアクセス
- ページネーション・フィルタリング機能

**エラーケース**
- 不正なパラメータ
- 認証失敗
- 存在しないリソース
- 必須フィールドの欠如

**エッジケース**
- 境界値テスト
- 重複データの処理
- 過度に大きなリクエスト

**パフォーマンステスト**
- レスポンス時間測定
- 同時リクエスト処理
- メモリ使用量監視

### 🔒 セキュリティテスト (`security_test.js`)

**インジェクション攻撃**
- SQLインジェクション
- NoSQLインジェクション
- コマンドインジェクション

**クロスサイトスクリプティング (XSS)**
- 格納型XSS
- 反射型XSS
- DOM-based XSS

**認証・認可**
- 認証バイパス
- 権限昇格
- セッション固定攻撃

**入力検証**
- バッファオーバーフロー
- ファイルアップロード脆弱性
- パストラバーサル

**情報漏洩**
- エラーメッセージからの情報開示
- 設定ファイルへの不正アクセス
- デバッグ情報の露出

### ⚡ パフォーマンステスト (`performance_monitor.js`)

**レスポンス時間測定**
- 各エンドポイントのレスポンス時間
- 平均・最大・最小値の算出
- パフォーマンス閾値の監視

**同時実行テスト**
- 複数リクエストの並行処理
- リソース競合の確認
- スループット測定

**継続監視**
- 定期的なパフォーマンスチェック
- アラート機能
- トレンド分析

## 使用方法

### 📦 前提条件

```bash
# 依存関係のインストール
npm install

# API サーバーが起動していることを確認
npm run dev
```

### 🚀 個別テスト実行

```bash
# 包括的APIテスト
npm run test:api:comprehensive

# セキュリティテスト
npm run test:security

# パフォーマンステスト（単発）
npm run test:performance

# パフォーマンス継続監視（5分間隔）
npm run test:performance:watch

# 基本APIテスト
npm run test:api
```

### 🔄 統合テスト実行

```bash
# 全テストを順次実行
npm run test:all

# または直接実行
node test/run_all_tests.js
```

### 📊 テスト結果の確認

統合テスト実行後、以下のファイルが生成されます：

- `test/test-report.json` - 詳細なテスト結果（JSON形式）
- コンソール出力 - 見やすい形式のサマリーレポート

## テスト結果の解釈

### ✅ 成功条件

- **包括的テスト**: 全テストケースが成功
- **セキュリティテスト**: 脆弱性が0件
- **パフォーマンステスト**: 平均レスポンス時間 < 2秒

### ⚠️ 警告条件

- **パフォーマンス**: 平均レスポンス時間 2-5秒
- **セキュリティ**: グレードB以下
- **機能**: 一部の非重要テストが失敗

### 🚨 重要な問題

- **セキュリティ脆弱性**: 即座に修正が必要
- **機能テスト失敗**: APIの動作に問題
- **重大なパフォーマンス問題**: レスポンス時間 > 5秒

## 設定とカスタマイズ

### 🔧 パフォーマンス閾値の変更

`performance_monitor.js` の `PERFORMANCE_THRESHOLDS` を編集：

```javascript
const PERFORMANCE_THRESHOLDS = {
  warning: 2000,  // 警告レベル (ms)
  critical: 5000, // 重要レベル (ms)
  timeout: 30000  // タイムアウト (ms)
};
```

### 🎯 監視対象エンドポイントの追加

`performance_monitor.js` の `ENDPOINTS_TO_MONITOR` に追加：

```javascript
{
  path: '/api/new-endpoint',
  method: 'GET',
  requiresAuth: true
}
```

### 🔒 セキュリティテストのカスタマイズ

`security_test.js` でペイロードを追加・変更可能：

```javascript
const sqlPayloads = [
  "既存のペイロード",
  "新しいSQLインジェクションペイロード"
];
```

## CI/CD統合

### GitHub Actions

```yaml
name: API Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-node@v2
        with:
          node-version: '18'
      - run: npm install
      - run: npm run test:all
```

### 結果の通知

テスト失敗時にSlack通知を送信する例：

```bash
# テスト実行とSlack通知
npm run test:all || curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"JitsuFlow API tests failed!"}' \
  YOUR_SLACK_WEBHOOK_URL
```

## トラブルシューティング

### よくある問題

**Q: 認証テストが失敗する**
```
A: デモアカウントの認証情報を確認してください
   - user@jitsuflow.app / demo123
   - admin@jitsuflow.app / admin123
```

**Q: パフォーマンステストがタイムアウトする**
```
A: API サーバーが起動していることを確認し、
   PERFORMANCE_THRESHOLDS.timeout を増やしてください
```

**Q: セキュリティテストで偽陽性が発生する**
```
A: 実装の仕様に応じて、テストケースを調整してください
```

### ログ出力の詳細化

デバッグモードでの実行：

```bash
DEBUG=1 npm run test:api:comprehensive
```

## 拡張とカスタマイズ

### 新しいテストの追加

1. `comprehensive_api_test.js` に新しいテスト関数を追加
2. `runAllTests()` 関数でテストを実行
3. 必要に応じてエラーハンドリングを追加

```javascript
async function testNewFeature() {
  // テストロジック
  return { success: true };
}

// メイン関数で実行
await runTest('New Feature Test', testNewFeature);
```

### カスタムレポート形式

`run_all_tests.js` の `displayReport()` 関数をカスタマイズして、
独自のレポート形式を作成できます。

## リソース

- [JitsuFlow API ドキュメント](../API_DOCUMENTATION.md)
- [セキュリティベストプラクティス](https://owasp.org/www-project-web-security-testing-guide/)
- [パフォーマンステストガイド](https://web.dev/performance/)

## 貢献

テストスイートの改善にご協力ください：

1. 新しいテストケースの提案
2. バグレポート
3. パフォーマンス改善
4. ドキュメントの更新

プルリクエストをお待ちしています！