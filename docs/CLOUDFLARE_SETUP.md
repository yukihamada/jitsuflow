# Cloudflare API Token設定ガイド

## 現在の状況

CI/CDパイプラインは正常に動作していますが、Cloudflareへのデプロイで認証エラーが発生しています。

## 必要なAPI Token権限

Cloudflare Workersをデプロイするには、以下の権限が必要です：

### 最小限の権限:
1. **Account** → **Cloudflare Workers Scripts:Edit**
2. **Account** → **Account Settings:Read**
3. **User** → **User Details:Read**

### D1データベースを使用する場合:
4. **Account** → **D1:Edit**

### R2ストレージを使用する場合:
5. **Account** → **Workers R2 Storage:Edit**

### KVネームスペースを使用する場合:
6. **Account** → **Workers KV Storage:Edit**

## API Tokenの作成手順

1. [Cloudflare Dashboard](https://dash.cloudflare.com/profile/api-tokens)にアクセス
2. "Create Token"をクリック
3. "Custom token"を選択
4. トークン名: `JitsuFlow CI/CD`
5. 上記の権限を追加
6. アカウントリソースを選択
7. "Continue to summary" → "Create Token"

## トラブルシューティング

### エラー: "Authentication error [code: 10000]"
- API Tokenの権限が不足しています
- 特に`User Details:Read`権限が必要です

### エラー: "Unable to retrieve email for this user"
- `User → User Details → Read`権限を追加してください

## 代替案

もしAPI Tokenの権限設定が難しい場合は、以下の代替案があります：

1. **Global API Key**を使用（推奨されませんが動作します）
   - Email + Global API Keyの組み合わせ
   - より多くの権限を持つため、セキュリティリスクがあります

2. **手動デプロイ**
   - ローカルで`wrangler deploy`を実行
   - CI/CDはテストのみに使用

## 次のステップ

1. 新しいAPI Tokenを作成（上記の権限を含む）
2. GitHubのSecretを更新
3. CI/CDパイプラインを再実行