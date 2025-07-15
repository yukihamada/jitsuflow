# TestFlight ID 交換が必要

現在、ランディングページには以下のプレースホルダーが含まれています：

- ファイル: `/Users/yuki/jitsuflow/landing-page/public/index.html`
- 行番号: 235
- 現在の値: `YOUR_TESTFLIGHT_ID`

## 変更が必要な箇所

```html
<a href="https://testflight.apple.com/join/YOUR_TESTFLIGHT_ID" class="...">
```

## 変更方法

実際のTestFlight IDを取得したら、以下のコマンドを実行：

```bash
# TestFlight IDを置き換え（例：実際のIDが "abc123def" の場合）
sed -i '' 's/YOUR_TESTFLIGHT_ID/abc123def/g' /Users/yuki/jitsuflow/landing-page/public/index.html

# 変更を確認
grep testflight.apple.com /Users/yuki/jitsuflow/landing-page/public/index.html

# デプロイ
cd /Users/yuki/jitsuflow/landing-page
npx wrangler pages deploy public --project-name jitsuflow
```

## TestFlight IDの取得方法

1. App Store Connectにログイン
2. TestFlightセクションに移動
3. JitsuFlowアプリを選択
4. 「パブリックリンク」または「TestFlightの公開リンク」を確認
5. URLの最後の部分がTestFlight ID（例：https://testflight.apple.com/join/abc123def）