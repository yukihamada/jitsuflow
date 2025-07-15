# 🔑 App Store Connect APIキー ダウンロード直接リンク

## 📱 ステップ1: App Store Connectにログイン

以下のリンクをクリックして直接APIキーページにアクセス:

### [→ App Store Connect APIキーページを開く](https://appstoreconnect.apple.com/access/api)

ログイン情報:
- メール: `mail@yukihamada.jp`
- 2段階認証が必要です

## 📥 ステップ2: APIキーをダウンロード

1. **新しいキーを作成する場合:**
   - 「キーを生成」ボタン（＋アイコン）をクリック
   - キー名: `JitsuFlow API`
   - アクセス: `App Manager`
   - 「生成」をクリック

2. **既存のキーを使用する場合:**
   - Key ID `TYAN6W54AG` を探す
   - 「APIキーをダウンロード」リンクをクリック

## ⚠️ 重要な確認事項

**ダウンロードしたファイルを確認:**
- ファイル名: `AuthKey_TYAN6W54AG.p8` (または新しいKey ID)
- ファイルサイズ: 200バイト以上あることを確認
- 空のファイル（0バイト）ではないことを確認

## 🚀 ステップ3: ファイルを配置

ターミナルで以下のコマンドを実行:

```bash
# ダウンロードしたファイルを移動（Key IDを確認して実行）
mv ~/Downloads/AuthKey_TYAN6W54AG.p8 /Users/yuki/jitsuflow/fastlane/authkey/

# 権限を設定
chmod 600 /Users/yuki/jitsuflow/fastlane/authkey/AuthKey_TYAN6W54AG.p8

# ファイルサイズを確認（0バイトでないこと）
ls -la /Users/yuki/jitsuflow/fastlane/authkey/AuthKey_*.p8
```

## 📝 新しいKey IDの場合

新しいキーを作成した場合は、Key IDを更新:

```bash
# Fastfileを編集
# 8行目の key_id = "TYAN6W54AG" を新しいKey IDに変更
```

## ✅ 確認コマンド

```bash
# APIキー設定を確認
./scripts/check_api_key.sh
```

## 🎯 最終ステップ

APIキーが正しく配置されたら:

```bash
# メタデータをアップロード
make ios-metadata

# または
/opt/homebrew/lib/ruby/gems/3.2.0/bin/fastlane ios metadata_only
```