# 🔑 App Store Connect APIキー作成 - 正しい手順

## ステップ1: App Store Connectにログイン

1. **メインページにアクセス**
   ```
   https://appstoreconnect.apple.com/
   ```

2. **ログイン**
   - メール: `mail@yukihamada.jp`
   - パスワードと2段階認証

## ステップ2: ユーザーとアクセスページへ移動

ログイン後、以下のいずれかの方法で移動:

### 方法A: トップメニューから
1. 画面上部の自分の名前/アイコンの隣にあるメニューをクリック
2. 「ユーザーとアクセス」を選択

### 方法B: 直接URLアクセス
```
https://appstoreconnect.apple.com/access/users
```

## ステップ3: APIキーセクションへ移動

1. 「ユーザーとアクセス」ページが開いたら
2. 左側のサイドバーで「統合」セクションを探す
3. 「App Store Connect API」をクリック

または、ページ上部のタブから「キー」を選択

## ステップ4: 新しいAPIキーを生成

### 🔵 キーの生成

1. **「キーを生成」ボタンをクリック**（＋アイコンまたは青いボタン）

2. **キー情報を入力:**
   - **名前**: `JitsuFlow Fastlane Key`
   - **アクセス**: `App Manager` を選択
     - これでアプリの管理、メタデータ更新、ビルドアップロードが可能

3. **「生成」ボタンをクリック**

## ステップ5: キー情報を記録してダウンロード

キー生成後、以下の情報が表示されます:

1. **Key ID**: 例 `ABC123XYZ` （10文字）
2. **Issuer ID**: `69a6de7e-xxxx-xxxx-xxxx-xxxxxxxxxxxx` 形式

### 📥 ダウンロード

1. **「APIキーをダウンロード」リンクをクリック**
2. ファイル名: `AuthKey_[KEY_ID].p8`
3. **このファイルは一度しかダウンロードできません！**

## ステップ6: ダウンロードしたファイルの確認

```bash
# ダウンロードフォルダを確認
ls -la ~/Downloads/AuthKey_*.p8

# ファイルサイズが200バイト程度あることを確認
# 例: -rw-r--r--@ 1 yuki staff 223 Jan 12 23:30 AuthKey_ABC123XYZ.p8
```

## ステップ7: Fastlane設定を更新

1. **ファイルを移動**
   ```bash
   # 例: Key IDが ABC123XYZ の場合
   mv ~/Downloads/AuthKey_ABC123XYZ.p8 /Users/yuki/jitsuflow/fastlane/authkey/
   chmod 600 /Users/yuki/jitsuflow/fastlane/authkey/AuthKey_ABC123XYZ.p8
   ```

2. **Fastfileを更新**
   ```bash
   # fastlane/Fastfileの8-10行目を編集
   ```
   
   以下のように変更:
   ```ruby
   key_id = "ABC123XYZ"  # 新しいKey ID
   issuer_id = "69a6de7e-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  # 表示されたIssuer ID
   key_filepath = "./fastlane/authkey/AuthKey_ABC123XYZ.p8"
   ```

## トラブルシューティング

### 「ユーザーとアクセス」が表示されない場合:
- アカウントの権限が「Admin」または「App Manager」である必要があります
- 組織/チームに所属している必要があります

### APIキーセクションが見つからない場合:
1. 個人開発者アカウントの場合、表示が異なる可能性があります
2. 「アプリ」→ 特定のアプリを選択 → 「App Store Connect API」を探す

### 代替方法:
もしAPIキーが作成できない場合は、Fastlaneの対話型認証を使用:
```bash
# APIキーなしで実行（Apple IDとパスワードで認証）
/opt/homebrew/lib/ruby/gems/3.2.0/bin/fastlane ios metadata_only
```

## 🎯 次のステップ

正しくAPIキーをセットアップしたら:
```bash
# 設定確認
./scripts/check_api_key.sh

# メタデータアップロード
make ios-metadata
```