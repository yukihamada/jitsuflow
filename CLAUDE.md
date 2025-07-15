CLAUDE.md – 🚀 JitsuFlow 完全ガイドライン

1. 🔥 プロジェクトのミッション

『JitsuFlow』はブラジリアン柔術の練習・道場運営を最も効率的に行える唯一無二のプラットフォームを提供し、世界中の柔術コミュニティを強化・発展させることを目的とします。

2. 🌟 目標指標（North-Star Metrics）
	•	道場予約にかかる時間を80%以上短縮
	•	プレミアム課金コンテンツ（動画）の継続率90%以上
	•	月間アクティブユーザー(MAU)を毎月安定的に増加

3. 🛠 技術スタック

カテゴリ	使用技術・フレームワーク
フロントエンド	Flutter, Jaspr (SSR, SEO最適化)
バックエンド	Cloudflare Workers, R2, D1
課金・通知	Stripe, Google Chat Webhook, ReSend
テスト	Playwright (E2E自動テスト), Jest (単体テスト)
分析	Cloudflare Web Analytics, Google Analytics

4. 📌 開発の指針
	•	すべての変更はclaude.json経由で自動化を徹底
	•	マニュアル操作を排除、すべてCI/CDパイプライン内で完結
	•	E2Eおよび単体テストを必ず通過したもののみデプロイ許可
	•	Claude Codeは常に最新の安定版を使用

5. 📑 要件定義テンプレート（必須）

### 🔹 機能名
-
### 📍 目的・提供価値
-
### 📖 機能詳細
-
### ⚙️ 技術仕様
- インフラ:
- DB設計:
- API:
### 💳 課金要素
-
### 🚩 優先度（MVPか後回しか）
-
### ⚠️ 制約条件・注意点
-

6. 💡 課金戦略
	•	フリープラン：限定機能、週2回の予約
	•	プレミアム（月額）：予約無制限、限定動画・ライブ配信参加権
	•	年払いディスカウント（15%OFF）で継続利用促進
	•	初回1ヶ月間無料トライアル提供

7. 📐 設計思想（Claude Codeとの連携強化）
	•	JSON設定ファイル (claude.json) は常に明快かつ短く維持
	•	Claude Codeは並列実行を最大限活用（concurrency: 8）
	•	新機能追加時は即座に要件定義を CLAUDE.md に記載し、Claude Codeに通知

8. ✅ 開発・デプロイフロー
	•	GitHub Flow準拠 (featureブランチ→develop→main)
	•	PRは最低1名のコードレビューを経てマージ
	•	CI/CDによるE2E・単体テストを通過後、自動デプロイ
	•	デプロイ成功時Slack通知、障害時自動ロールバック

9. 🔄 QAフロー
	•	テスト環境（Staging）で常時E2E・単体自動テスト
	•	定期的にQA担当が手動で回帰テスト実施
	•	Slackでバグ報告専用チャネルを運営
	•	障害発生時の復旧フロー・エスカレーションルールを明確化

10. 📊 コスト管理ルール
	•	月間予算: 500 USD (使用率80%でアラートメール)
	•	月次で予算内訳を確認・最適化を実施
	•	クォータ管理を定期的に監視

11. 👥 開発チーム役割（明確化）

担当	内容
プロダクト管理	要件定義、仕様確認、ユーザーフィードバック収集
フロントエンド	Flutterアプリ開発、SEO最適化
バックエンド	Cloudflareインフラ設定、API開発、DB管理
課金・通知	Stripe統合、通知設定・運用
QA	テスト計画、実施、品質管理

12. 📱 TestFlightアップロード手順

### 前提条件
- Apple Developer Programへの登録
- App Store Connectでのアプリ作成
- App-specific passwordの取得（https://appleid.apple.com で生成）

### 手順

#### 1. ビルド番号の更新
```bash
# pubspec.yamlを編集
# version: 1.0.0+1 → version: 1.0.0+2
# +以降の数字をインクリメント
```

#### 2. IPAファイルのビルド
```bash
flutter build ipa --release
```

#### 3. TestFlightへのアップロード
```bash
xcrun altool --upload-app \
  -f build/ios/ipa/JitsuFlow.ipa \
  -t ios \
  -u あなたのApple ID \
  -p あなたのApp-specific password
```

### よくあるエラーと対処法

| エラー | 原因 | 対処法 |
|---|---|---|
| "The bundle version must be higher" | ビルド番号が重複 | pubspec.yamlのビルド番号をインクリメント |
| "Invalid Signature" | 不正なファイルが含まれている | `flutter clean` 後に再ビルド |
| "Authentication failed" | パスワードが違う | App-specific passwordを再生成 |

### 自動化スクリプト
```bash
#!/bin/bash
# scripts/upload_testflight.sh

# 現在のビルド番号を取得
CURRENT_BUILD=$(grep "version:" pubspec.yaml | sed 's/.*+//')
NEW_BUILD=$((CURRENT_BUILD + 1))

# pubspec.yamlを更新
sed -i "" "s/version: \(.*\)+.*/version: \1+$NEW_BUILD/" pubspec.yaml

# ビルド実行
flutter build ipa --release

# TestFlightにアップロード
xcrun altool --upload-app \
  -f build/ios/ipa/JitsuFlow.ipa \
  -t ios \
  -u $APPLE_ID \
  -p $APP_SPECIFIC_PASSWORD
```

## 13. ⚡ ビルド高速化

### Flutterビルド最適化

#### 1. ビルドキャッシュの活用
```bash
# .gitignoreに追加しないファイル
build/
.dart_tool/
ios/Pods/
```

#### 2. 並列ビルドの有効化
```bash
# ios/Runner.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings
<key>BuildSystemType</key>
<string>Latest</string>
```

#### 3. デバッグビルドの高速化
```bash
# Debug時のみ有効
export FLUTTER_BUILD_MODE=debug
flutter build ios --debug --simulator
```

### Xcodeビルド設定

#### 1. ビルド設定の最適化
- Build Settings > Build Options
  - `Debug Information Format` = `DWARF`（Debug時）
  - `Enable Bitcode` = `No`
  - `Strip Debug Symbols` = `No`（Debug時）

#### 2. 不要なアーキテクチャの除外
```bash
# Podfileに追加
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
    end
  end
end
```

### ビルド時間短縮Tips

1. **依存関係の整理**
   ```bash
   flutter pub deps | grep -E "^[|+]-" | wc -l
   # 依存数を確認し、不要なものを削除
   ```

2. **CocoaPodsのキャッシュ活用**
   ```bash
   pod install --repo-update
   export COCOAPODS_DISABLE_STATS=true
   ```

3. **インクリメンタルビルド**
   ```bash
   # 小さな変更のみの場合
   flutter build ios --incremental
   ```

## 14. 🧑‍💻 トラブルシューティング（随時更新）

問題例	解決策
課金処理失敗	StripeのWebhookログ確認、再送信対応
デプロイエラー	Cloudflare Workersログ確認、迅速なロールバック
動画アップロード失敗	R2の容量制限・権限設定を確認・再設定
ビルドが遅い	上記のビルド高速化Tipsを適用

## 15. 🚀 クイックコマンド

### TestFlightアップロード（環境変数設定後）
```bash
export APPLE_ID='your-email@example.com'
export APP_SPECIFIC_PASSWORD='xxxx-xxxx-xxxx-xxxx'
./scripts/upload_testflight.sh
```

### 高速デバッグビルド
```bash
./scripts/fast_build.sh --debug
```

### リリースビルド
```bash
./scripts/fast_build.sh --release
```

⸻

🚀 まとめ
本ドキュメントを開発メンバーが常に最新化し、参照・実行することで、『JitsuFlow』プロジェクトは高品質でスケーラブルな状態を維持します。すべてのメンバーが本ガイドラインを基準に行動し、常に最新情報を共有することを徹底します。
