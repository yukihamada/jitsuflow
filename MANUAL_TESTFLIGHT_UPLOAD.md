# 📱 手動TestFlightアップロード手順

## 現在の状況

- ✅ アーカイブファイル作成済み: `build/Runner.xcarchive`
- ✅ ビルド番号: 1.0.0 (5) 
- ✅ アプリアイコン含まれています
- ✅ Xcode Organizerが開いています

## 🚀 Xcode Organizerでのアップロード手順

### ステップ1: アーカイブを確認
1. **Xcode Organizer**が開いているのを確認
2. **JitsuFlow (1.0.0)** アーカイブが表示されているか確認
3. **最新の日時**のアーカイブを選択

### ステップ2: アプリを配布
1. **「Distribute App」ボタンをクリック**
2. **配布方法を選択**:
   - ✅ **「App Store Connect」**を選択
   - 「Next」をクリック

### ステップ3: 配布オプション
1. **「Upload」**を選択
2. **「Next」をクリック**

### ステップ4: App Store Connect オプション
1. **以下を確認・選択**:
   - ✅ **「Upload your app's symbols」**（推奨）
   - ✅ **「Manage Version and Build Number」**（Xcode管理）
2. **「Next」をクリック**

### ステップ5: 署名
1. **「Automatically manage signing」**を選択
2. **Team**: `Yuki Hamada (5BV85JW8US)` が選択されていることを確認
3. **「Next」をクリック**

### ステップ6: レビューと確定
1. **アプリ情報を確認**:
   - アプリ名: JitsuFlow
   - バージョン: 1.0.0
   - ビルド: 5
   - Bundle ID: app.jitsuflow.jitsuflow
2. **「Upload」ボタンをクリック**

## ⏳ アップロード処理

### 進行状況
- **「Uploading...」**: アプリをAppleサーバーにアップロード中
- **「Processing...」**: Appleサーバーで検証中
- **完了**: 「Upload Successful」メッセージ

### 所要時間
- **アップロード**: 2-10分（ファイルサイズによる）
- **検証**: 5-30分（初回は長くなることがある）

## 📱 App Store Connectで確認

### アップロード完了後
1. **App Store Connectにアクセス**:
   ```
   https://appstoreconnect.apple.com/
   ```

2. **TestFlightを確認**:
   - マイApp → JitsuFlow → TestFlight
   - 新しいビルド 1.0.0 (5) が表示される

3. **処理状況をチェック**:
   - ✅ **「準備完了」**: すぐにテスト可能
   - ⏳ **「処理中」**: Appleの検証中（待機）
   - ❌ **「エクスポートコンプライアンス不足」**: 設定が必要

## 🔧 エクスポートコンプライアンス設定

もし「エクスポートコンプライアンス情報がありません」と表示された場合：

1. **ビルドをクリック**
2. **質問に回答**:
   - 「アプリで暗号化を使用していますか？」
   - → **「いいえ」**を選択（HTTPSのみ使用）
3. **「保存」をクリック**

## ✅ 最終確認

### TestFlightアプリで確認
1. **iPhone/iPadのTestFlightアプリを開く**
2. **Apple IDでログイン** (mail@yukihamada.jp)
3. **JitsuFlowが表示されることを確認**
4. **「インストール」ボタンが表示される**

### 成功の目安
- ✅ App Store ConnectのTestFlightに表示される
- ✅ ビルド番号5が最新として表示される
- ✅ アプリアイコンが正しく表示される
- ✅ TestFlightアプリでインストール可能

## 🚨 トラブルシューティング

### よくある問題
1. **「Invalid Signature」**: 証明書の期限切れ
2. **「Missing Compliance」**: エクスポートコンプライアンス未設定
3. **「Processing for a long time」**: 初回は1時間程度かかることがある

### 解決策
- 証明書を更新してアーカイブを再作成
- エクスポートコンプライアンスで「いいえ」を選択
- 処理完了まで待機（週末は遅い場合がある）

---

**次のステップ**: Xcode Organizerでアップロード完了後、App Store Connectで確認してください。