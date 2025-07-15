# 🚀 JitsuFlow App Store Connect 自動アップロードガイド

## 📋 概要

JitsuFlowアプリをApp Store Connectに自動でアップロードするためのシステムが完全に設定されました。

## ✅ 完了した設定

### 1. Fastlane設定
- ✅ Fastlaneがインストールされました
- ✅ `fastlane/Fastfile` に以下のレーンを設定:
  - `create_app` - App Store Connectでアプリを作成
  - `metadata_only` - メタデータとスクリーンショットのアップロード
  - `beta` - TestFlightへのアップロード
  - `release` - 完全なApp Store提出フロー

### 2. メタデータ設定
- ✅ `/fastlane/metadata/ja-JP/` にすべてのメタデータファイルが準備済み
- ✅ アプリ名: JitsuFlow
- ✅ Bundle ID: app.jitsuflow.jitsuflow
- ✅ 日本語の説明文、キーワードなど完備

### 3. スクリーンショット設定
- ✅ `/fastlane/screenshots/ja-JP/` にスクリーンショットを配置
- ✅ iPhone 6.7インチ (iPhone 15 Pro Max)用
- ✅ iPhone 6.1インチ (iPhone 15 Pro)用
- ✅ iPad 12.9インチ (iPad Pro)用
- ✅ 6枚のスクリーンショット (ホーム、予約、プロフィール、動画など)

### 4. 自動化スクリプト
- ✅ `scripts/ios_appstore_upload.sh` - 包括的なアップロードスクリプト
- ✅ `Makefile` にApp Store関連コマンドを追加

## 🔧 次のステップ（重要）

### Step 1: App Store Connect API Keyの設定

App Store Connectでの認証を自動化するため、APIキーの設定が必要です：

1. **App Store Connect APIキーを作成:**
   ```
   https://appstoreconnect.apple.com/ → ユーザーとアクセス → キー
   ```

2. **APIキーをダウンロード:**
   ```
   AuthKey_XXXXXXXXX.p8 ファイルを以下に配置:
   /Users/yuki/jitsuflow/fastlane/authkey/AuthKey_XXXXXXXXX.p8
   ```

3. **環境変数を設定:**
   ```bash
   export ASC_KEY_ID="XXXXXXXXX"  # キーID
   export ASC_ISSUER_ID="YYYYYYYY-YYYY-YYYY-YYYY-YYYYYYYYYYYY"  # Issuer ID
   export ASC_KEY_PATH="/Users/yuki/jitsuflow/fastlane/authkey/AuthKey_XXXXXXXXX.p8"
   ```

詳細手順: `fastlane/API_KEY_SETUP.md` を参照

### Step 2: アップロード実行

#### メタデータのみアップロード（推奨最初のステップ）
```bash
# 方法1: Makefileを使用
make ios-metadata

# 方法2: スクリプトを使用
./scripts/ios_appstore_upload.sh metadata

# 方法3: Fastlaneを直接使用
fastlane ios metadata_only
```

#### TestFlightにアップロード
```bash
make ios-beta
# または
./scripts/ios_appstore_upload.sh beta
```

#### 審査に提出（完全フロー）
```bash
make ios-release
# または
./scripts/ios_appstore_upload.sh release
```

## 📱 利用可能なコマンド

### Makefileコマンド
```bash
make ios-create      # App Store Connectでアプリを作成
make ios-metadata    # メタデータとスクリーンショットをアップロード
make ios-beta        # TestFlightにアップロード
make ios-release     # 審査に提出
make setup-fastlane  # Fastlaneをインストール
```

### 自動化スクリプト
```bash
./scripts/ios_appstore_upload.sh metadata  # メタデータのみ
./scripts/ios_appstore_upload.sh beta      # TestFlight
./scripts/ios_appstore_upload.sh release   # 審査提出
```

## ⚠️ 注意事項

1. **API Key設定なしの場合**
   - 2段階認証による手動ログインが必要になります
   - 自動化には必ずAPI Keyを設定してください

2. **ビルドが必要なレーン**
   - `beta` と `release` レーンはXcodeでのビルドが必要です
   - 事前にXcodeプロジェクトが正しく設定されていることを確認してください

3. **初回実行**
   - 最初は `metadata_only` レーンで動作確認することを推奨します

## 🎯 推奨実行順序

1. **API Key設定** (fastlane/API_KEY_SETUP.md参照)
2. **メタデータテスト**: `make ios-metadata`
3. **TestFlightアップロード**: `make ios-beta`
4. **審査提出**: `make ios-release`

## 📞 サポート

- API Key設定: `fastlane/API_KEY_SETUP.md`
- エラーが発生した場合: ログを確認して、必要に応じてAPIキー設定を見直してください

これで、JitsuFlowアプリのApp Store Connectへの自動アップロードシステムが完全に準備できました！ 🎉