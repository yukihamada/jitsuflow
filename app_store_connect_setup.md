# JitsuFlow App Store Connect セットアップガイド

## 1. App Store Connectでアプリを作成

1. [App Store Connect](https://appstoreconnect.apple.com) にログイン
2. 「マイApp」→「+」→「新規App」をクリック
3. 以下の情報を入力：
   - **プラットフォーム**: iOS
   - **アプリ名**: JitsuFlow
   - **プライマリ言語**: 日本語
   - **Bundle ID**: app.jitsuflow.jitsuflow
   - **SKU**: JITSUFLOW001
   - **ユーザーアクセス**: フルアクセス

## 2. App情報を設定

### 基本情報
- **カテゴリ**: スポーツ
- **サブカテゴリ**: 格闘技

### 説明文
```
JitsuFlowは、ブラジリアン柔術の練習と道場管理を革新するアプリです。

【主な機能】
• 道場の予約システム
• インストラクター情報の閲覧
• 技術動画の視聴（無料・プレミアム）
• スキルアセスメント（15の基本技術）
• トレーニング履歴の記録
• ショップ機能（道着・装備品）
• メンバー管理（管理者向け）

【特徴】
- 簡単な予約システムで練習時間を効率化
- プロのインストラクターによる技術解説動画
- 自分の上達を可視化するスキル評価機能
- 道場運営者向けの充実した管理機能

柔術を始めたばかりの初心者から、道場を運営する上級者まで、すべての柔術愛好家のためのアプリです。
```

### キーワード
- ブラジリアン柔術
- BJJ
- 格闘技
- トレーニング
- 道場
- スポーツ
- 武道
- フィットネス

### スクリーンショット (必須)
- 6.7インチ (iPhone 15 Pro Max)
- 6.5インチ (iPhone 14 Plus)
- 5.5インチ (iPhone 8 Plus)
- iPad Pro (12.9インチ)

## 3. 価格とプラン

- **価格**: 無料
- **App内課金**: あり
  - プレミアムメンバーシップ（月額）
  - プレミアムメンバーシップ（年額）

## 4. TestFlight情報

### 内部テスト
- **テスト内容**: 基本機能の動作確認
- **テスター数**: 最大100名

### 外部テスト
- **テスト内容**: 実際の道場での利用テスト
- **フィードバック項目**: 
  - 予約システムの使いやすさ
  - 動画再生の品質
  - 全体的なパフォーマンス

## 5. アップロード手順

1. IPAファイルの準備完了: `/Users/yuki/jitsuflow/build/ios/ipa/JitsuFlow.ipa`

2. App-specific passwordの作成:
   ```bash
   # Apple IDサイトでパスワードを生成後
   xcrun altool --store-password-in-keychain-item "JITSUFLOW_UPLOAD" \
     -u "mail@yukihamada.jp" \
     -p "生成されたパスワード"
   ```

3. TestFlightへアップロード:
   ```bash
   xcrun altool --upload-app \
     -f "/Users/yuki/jitsuflow/build/ios/ipa/JitsuFlow.ipa" \
     -t ios \
     -u "mail@yukihamada.jp" \
     --password "@keychain:JITSUFLOW_UPLOAD"
   ```

## 次のステップ

1. App Store Connectでアプリを作成
2. App-specific passwordを生成
3. IPAファイルをアップロード
4. TestFlightで内部テスターを招待
5. フィードバックを収集して改善