# JitsuFlow Cloudflare設定ガイド

## 現在のデプロイ状況

### 1. Cloudflare Pages (フロントエンド)
- **URL**: https://f6c4449e.jitsuflow.pages.dev
- **プロジェクト名**: jitsuflow
- **デプロイ済み**: ✅

### 2. Cloudflare Workers (API)
- **URL**: https://jitsuflow-worker.yukihamada.workers.dev
- **Worker名**: jitsuflow-worker
- **デプロイ済み**: ✅

## カスタムドメイン設定手順

### ステップ1: Cloudflareダッシュボードでドメインを追加

1. [Cloudflareダッシュボード](https://dash.cloudflare.com)にログイン
2. 「Websites」タブで「Add a site」をクリック
3. `jitsuflow.app`を入力
4. プランを選択（Free planで十分）
5. ネームサーバーの設定指示に従う

### ステップ2: ネームサーバーの変更

ドメインレジストラで以下のCloudflareネームサーバーに変更：
- 例: `nina.ns.cloudflare.com`
- 例: `todd.ns.cloudflare.com`

（実際のネームサーバーはCloudflareダッシュボードで確認）

### ステップ3: DNSレコードの設定

Cloudflareダッシュボード > DNS > Records で以下を追加：

```
# メインドメイン（フロントエンド）
Type: CNAME
Name: @
Target: jitsuflow.pages.dev
Proxy: ON (オレンジ雲)

# wwwサブドメイン（フロントエンド）
Type: CNAME
Name: www
Target: jitsuflow.pages.dev
Proxy: ON (オレンジ雲)

# APIサブドメイン
Type: CNAME
Name: api
Target: jitsuflow-worker.yukihamada.workers.dev
Proxy: ON (オレンジ雲)
```

### ステップ4: Pages カスタムドメイン設定

1. Cloudflareダッシュボード > Pages > jitsuflow
2. 「Custom domains」タブ
3. 「Add a custom domain」をクリック
4. `jitsuflow.app`を追加
5. `www.jitsuflow.app`も追加

### ステップ5: Workers カスタムドメイン設定

Workersのカスタムドメインは、wrangler.tomlで設定済み。
本番環境にデプロイ：

```bash
wrangler deploy --env production
```

### ステップ6: SSL/TLS設定

1. Cloudflareダッシュボード > SSL/TLS
2. 「Overview」で「Full (strict)」を選択
3. 「Edge Certificates」で以下を確認：
   - Always Use HTTPS: ON
   - Automatic HTTPS Rewrites: ON

## API URLの更新

Flutter アプリケーションの API URLを更新：

```dart
// lib/services/api_service.dart
static const String _baseUrl = 'https://api.jitsuflow.app/api';
```

または環境に応じて：

```dart
static String get _baseUrl {
  const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
  switch (environment) {
    case 'production':
      return 'https://api.jitsuflow.app/api';
    case 'staging':
      return 'https://staging-api.jitsuflow.app/api';
    default:
      return 'https://jitsuflow-worker.yukihamada.workers.dev/api';
  }
}
```

## デプロイコマンド

### フロントエンド（Pages）デプロイ
```bash
flutter build web
npx wrangler pages deploy build/web --project-name=jitsuflow
```

### API（Workers）デプロイ
```bash
# 開発環境
wrangler deploy

# 本番環境
wrangler deploy --env production
```

## 確認事項

1. **ネームサーバーの変更**: 最大48時間かかる場合があります
2. **SSL証明書**: Cloudflareが自動的に発行します
3. **キャッシュ**: 初回アクセス時は少し時間がかかる場合があります

## トラブルシューティング

### DNS伝播の確認
```bash
dig jitsuflow.app
nslookup jitsuflow.app
```

### SSL証明書の確認
```bash
openssl s_client -connect jitsuflow.app:443 -servername jitsuflow.app
```

### Cloudflare設定の確認
- ダッシュボード > Analytics でトラフィックを確認
- ダッシュボード > Security でセキュリティイベントを確認