# Admin Dashboard カスタムドメイン設定手順

admin.jitsuflow.app を Cloudflare Pages プロジェクトに設定する手順です。

## 自動設定方法（推奨）

現在、Cloudflare Pages のカスタムドメイン設定はダッシュボードから行う必要があります。

## 手動設定手順

1. **Cloudflareダッシュボードにログイン**
   - https://dash.cloudflare.com にアクセス
   - アカウントにログイン

2. **Pagesプロジェクトに移動**
   - 左メニューから「Workers & Pages」を選択
   - 「jitsuflow-admin」プロジェクトをクリック

3. **カスタムドメインを追加**
   - 「Custom domains」タブを選択
   - 「Set up a custom domain」ボタンをクリック
   - `admin.jitsuflow.app` を入力
   - 「Continue」をクリック

4. **DNSレコードの確認**
   - Cloudflareが自動的にDNSレコードを設定
   - 設定が完了するまで数分待つ

## 確認方法

設定が完了したら、以下のコマンドで確認：

```bash
curl -I https://admin.jitsuflow.app
```

HTTP 200が返ってきたら成功です。

## 現在の状態

- Pages プロジェクト: https://jitsuflow-admin.pages.dev ✅
- カスタムドメイン: admin.jitsuflow.app（設定待ち）⏳
- 管理画面の機能: 全て実装済み ✅

## トラブルシューティング

もし「Domain already exists」エラーが出た場合：

1. Workers の設定から admin.jitsuflow.app を削除済み ✅
2. 少し時間を置いてから再試行
3. それでもダメな場合は、一度別のサブドメインで試してから戻す