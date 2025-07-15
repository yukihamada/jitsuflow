# 🔧 TestFlight表示問題の解決方法

## 問題の原因

TestFlightにJitsuFlowアプリが表示されない理由：

1. **IPAファイルが作成されていない**
   - アーカイブは作成されたが、IPAエクスポートが未完了
   - ディスク容量不足によりエクスポートが失敗

2. **App Store Connectにアップロードされていない**
   - ビルドファイルがTestFlightに送信されていない

## 🚀 解決手順

### 手順1: ディスク容量の確保
```bash
# Xcodeキャッシュをクリア
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/Library/Caches/com.apple.dt.Xcode/*

# Flutterプロジェクトをクリーン
flutter clean
```
✅ **完了済み** - 6.9GB の空き容量を確保

### 手順2: IPAファイルの作成
```bash
# ExportOptions.plistを作成済み
# Team ID: 5BV85JW8US
# Method: app-store

# IPAビルドを実行
flutter build ipa --export-options-plist=ios/ExportOptions.plist
```
⏳ **実行中** - 現在ビルド処理中

### 手順3: TestFlightアップロード
ビルド完了後、以下のいずれかの方法でアップロード：

**方法A: コマンドライン**
```bash
xcrun altool --upload-app \
  -f build/ios/ipa/Runner.ipa \
  -t ios \
  -u mail@yukihamada.jp \
  -p qnfu-dzev-lhjo-tdap
```

**方法B: Fastlane（推奨）**
```bash
/opt/homebrew/lib/ruby/gems/3.2.0/bin/fastlane ios beta
```

**方法C: Xcode Organizer**
```bash
# アーカイブをXcodeで開く
open build/ios/archive/Runner.xcarchive

# Xcode Organizer → Distribute App → App Store Connect
```

### 手順4: App Store Connectで確認

1. **ログイン**
   https://appstoreconnect.apple.com/

2. **TestFlightタブを確認**
   - マイApp → JitsuFlow → TestFlight
   - ビルドの処理状況を確認

3. **エクスポートコンプライアンス**
   - 「暗号化を使用していますか？」→ **いいえ**
   - HTTPSのみ使用のため

## 📱 TestFlightでの表示条件

アプリがTestFlightに表示されるための条件：

1. ✅ **Apple Developer Program加入済み**
2. ✅ **正しいBundle ID設定** (`app.jitsuflow.jitsuflow`)
3. ✅ **有効な証明書とプロビジョニングプロファイル**
4. ⏳ **IPAファイルのアップロード** (進行中)
5. ⏳ **Appleの処理完了** (10-30分)
6. ⏳ **エクスポートコンプライアンス回答** (必要に応じて)

## ⏰ 処理時間の目安

- **ビルド**: 5-10分
- **アップロード**: 2-5分
- **Apple処理**: 10-30分
- **TestFlight表示**: 処理完了後すぐ

## 🔍 トラブルシューティング

### よくある問題と解決策

1. **「処理中」のまま長時間**
   - 初回アップロードは時間がかかります
   - 最大2時間待つことがあります

2. **「エクスポートコンプライアンスがありません」**
   - App Store Connect → ビルド詳細で回答
   - 「いいえ」を選択

3. **証明書エラー**
   - Xcode → Preferences → Accounts で確認
   - 必要に応じて証明書を更新

## ✅ 次のアクション

1. **現在のビルド完了を待つ**
2. **IPAファイルをTestFlightにアップロード**
3. **App Store Connectで処理状況を確認**
4. **エクスポートコンプライアンスに回答**

完了後、TestFlightアプリでJitsuFlowが表示されるはずです。