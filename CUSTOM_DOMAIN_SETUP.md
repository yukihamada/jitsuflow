# JitsuFlow カスタムドメイン設定ガイド

## 手動設定手順（Cloudflareダッシュボード）

### 1. Cloudflare Pagesのカスタムドメイン設定

1. [Cloudflareダッシュボード](https://dash.cloudflare.com)にログイン
2. 左メニューから「Pages」を選択
3. 「jitsuflow」プロジェクトをクリック
4. 「Custom domains」タブを選択
5. 「Set up a custom domain」をクリック
6. 以下のドメインを追加：
   - `jitsuflow.app`
   - `www.jitsuflow.app`

### 2. Cloudflare Workers ルート設定（API用）

本番環境にWorkersをデプロイして、api.jitsuflow.appを設定：

```bash
# 本番環境にデプロイ
wrangler deploy --env production
```

### 3. 確認手順

カスタムドメインが正しく設定されているか確認：

```bash
# メインドメイン
curl -I https://jitsuflow.app

# WWWサブドメイン
curl -I https://www.jitsuflow.app

# API
curl https://api.jitsuflow.app/api/health
```

## 設定状況

### DNS設定 ✅
- jitsuflow.app → jitsuflow.pages.dev (CNAME)
- www.jitsuflow.app → jitsuflow.pages.dev (CNAME)
- api.jitsuflow.app → jitsuflow-worker.yukihamada.workers.dev (CNAME)

### 次の手順
1. Cloudflareダッシュボードで手動でカスタムドメインを追加
2. 数分待ってSSL証明書が発行されるのを確認
3. アプリケーションのAPI URLを更新

## トラブルシューティング

### エラー522（Connection timed out）
- Cloudflare Pagesでカスタムドメインが設定されていない
- ダッシュボードから手動で追加が必要

### SSL証明書エラー
- 証明書の発行には最大15分かかる場合がある
- Cloudflare > SSL/TLS > Edge Certificatesで状態を確認