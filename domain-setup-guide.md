# JitsuFlow ドメイン設定ガイド

## 現在の状況
- ✅ **jitsuflow.app** - メインサイト（設定済み）
- ✅ **api.jitsuflow.app** - API（設定済み）
- ❌ **admin.jitsuflow.app** - 管理画面（要設定）
- ❌ **www.jitsuflow.app** - リダイレクト（要設定）

## 設定手順

### 1. Cloudflare DNS設定

Cloudflareダッシュボード > DNS で以下を確認/追加：

```
タイプ  名前              コンテンツ              プロキシ
A       @                 192.0.2.1              ✅
A       www              192.0.2.1              ✅
A       api              192.0.2.1              ✅
A       admin            192.0.2.1              ✅
```

※ IPアドレス（192.0.2.1）はCloudflareのプロキシ用ダミーIP

### 2. admin.jitsuflow.app の設定

#### 方法A: 既存のFlutterアプリを管理画面として使用
```bash
# wrangler.toml に追加
[[env.production.routes]]
pattern = "admin.jitsuflow.app"
custom_domain = true

# デプロイ
npx wrangler deploy --env production
```

#### 方法B: 新しい管理画面を作成（Next.js + Cloudflare Pages）
```bash
# 1. 管理画面プロジェクト作成
npx create-next-app@latest jitsuflow-admin --typescript --tailwind --app

# 2. Cloudflare Pagesプロジェクト作成
cd jitsuflow-admin
npm run build
npx wrangler pages project create jitsuflow-admin

# 3. デプロイ
npx wrangler pages deploy .next --project-name=jitsuflow-admin

# 4. カスタムドメイン追加（Cloudflareダッシュボード）
# Pages > jitsuflow-admin > カスタムドメイン > admin.jitsuflow.app を追加
```

### 3. www.jitsuflow.app のリダイレクト設定

#### 最も簡単な方法：Page Rules
1. Cloudflareダッシュボード > Rules > Page Rules
2. 「Create Page Rule」をクリック
3. 設定：
   - URL: `www.jitsuflow.app/*`
   - Pick a Setting: `Forwarding URL`
   - Status Code: `301 - Permanent Redirect`
   - Destination URL: `https://jitsuflow.app/$1`
4. 「Save and Deploy」

#### 代替方法：Redirect Rules（推奨）
1. Cloudflareダッシュボード > Rules > Redirect Rules
2. 「Create rule」をクリック
3. 設定：
   - Rule name: `WWW to non-WWW redirect`
   - When incoming requests match:
     - Field: `Hostname`
     - Operator: `equals`
     - Value: `www.jitsuflow.app`
   - Then:
     - Type: `Dynamic`
     - Expression: `concat("https://jitsuflow.app", http.request.uri.path)`
     - Status code: `301`
4. 「Deploy」

### 4. 設定確認コマンド

```bash
# DNS確認
dig jitsuflow.app
dig www.jitsuflow.app
dig api.jitsuflow.app
dig admin.jitsuflow.app

# HTTPSリダイレクト確認
curl -I https://www.jitsuflow.app
curl -I https://admin.jitsuflow.app

# API動作確認
curl https://api.jitsuflow.app/api/health
```

## トラブルシューティング

### 問題: DNS_PROBE_FINISHED_NXDOMAIN
- 原因：DNSレコードが存在しない
- 解決：Cloudflare DNSでAレコードを追加

### 問題: 522 Connection timed out
- 原因：オリジンサーバーが応答しない
- 解決：Cloudflareプロキシを有効化（オレンジ雲）

### 問題: 404 Not Found
- 原因：ルーティングが設定されていない
- 解決：wrangler.tomlまたはPage Rulesを確認

## 推奨設定

1. **SSL/TLS設定**
   - SSL/TLS > Overview > Full (strict)

2. **セキュリティ設定**
   - Security > Settings > Security Level: Medium
   - Security > Bots > Bot Fight Mode: ON

3. **パフォーマンス設定**
   - Speed > Optimization > Auto Minify: ON (JS, CSS, HTML)
   - Speed > Optimization > Brotli: ON

## 次のステップ

1. admin.jitsuflow.app用の管理画面アプリを開発
2. 認証システムの実装（管理者のみアクセス可能）
3. APIとの連携設定
4. モニタリング設定（Cloudflare Analytics）