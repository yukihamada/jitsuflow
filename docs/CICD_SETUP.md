# CI/CD セットアップガイド

## 概要
このプロジェクトは、GitHub Actionsを使用して自動テストとCloudflareへのデプロイを行います。

## ワークフロー
1. **Push時**: テストを実行
2. **mainブランチへのpush**: テスト合格後、本番環境へ自動デプロイ
3. **developブランチへのpush**: テスト合格後、ステージング環境へ自動デプロイ

## セットアップ手順

### 1. Cloudflare API Tokenの取得
1. [Cloudflare Dashboard](https://dash.cloudflare.com/profile/api-tokens)にアクセス
2. "Create Token"をクリック
3. "Custom token"を選択
4. 以下の権限を設定:
   - Account: Cloudflare Workers Scripts:Edit
   - Account: Cloudflare Pages:Edit
   - Account: D1:Edit
   - Zone: Zone:Read

### 2. GitHub Secretsの設定
1. GitHubリポジトリの Settings → Secrets and variables → Actions
2. "New repository secret"をクリック
3. 以下のシークレットを追加:
   - `CLOUDFLARE_API_TOKEN`: 上記で作成したトークン

### 3. 環境別の設定（オプション）
wrangler.tomlに環境別の設定を追加:

```toml
# 本番環境（デフォルト）
name = "jitsuflow-worker"
main = "src/index.js"

# ステージング環境
[env.staging]
name = "jitsuflow-worker-staging"
vars = { ENVIRONMENT = "staging" }
```

## テストの実行

### ローカルでのテスト
```bash
# 単体テスト
npm run test:unit

# APIテスト（開発サーバーを起動してから）
npm run test:api

# 全てのテスト
npm run test:all
```

### CI環境でのテスト
pushすると自動的に以下が実行されます:
1. Lintチェック
2. 単体テスト
3. APIテスト

## デプロイフロー

### 自動デプロイ
- `main`ブランチ: 本番環境へ自動デプロイ
- `develop`ブランチ: ステージング環境へ自動デプロイ

### 手動デプロイ
```bash
# 本番環境
npm run deploy

# ステージング環境
npm run deploy -- --env staging
```

## トラブルシューティング

### デプロイが失敗する場合
1. Cloudflare API Tokenの権限を確認
2. wrangler.tomlの設定を確認
3. GitHub Actionsのログを確認

### テストが失敗する場合
1. ローカルでテストを実行して確認
2. 環境変数の設定を確認
3. データベースの状態を確認