# App Store Connect API Key セットアップガイド

App Store Connectに自動でアップロードするために、APIキーの設定が必要です。

## 1. App Store Connect APIキーの作成

1. https://appstoreconnect.apple.com/ にアクセス
2. 「ユーザーとアクセス」→「キー」をクリック
3. 「+」をクリックして新しいキーを作成
4. 以下の設定を行う：
   - 名前: `JitsuFlow Fastlane API Key`
   - アクセス: `Developer`
   - アプリへのアクセス: `すべてのアプリ`

## 2. APIキーファイルのダウンロード

1. 作成したキーの「ダウンロード」をクリック
2. `AuthKey_XXXXXXXXX.p8` ファイルをダウンロード
3. キーID（`XXXXXXXXX`の部分）をメモ
4. Issuer ID をメモ（キー一覧画面の上部に表示）

## 3. APIキーファイルの配置

ダウンロードした `AuthKey_XXXXXXXXX.p8` ファイルを以下の場所に配置：

```
/Users/yuki/jitsuflow/fastlane/authkey/AuthKey_XXXXXXXXX.p8
```

## 4. 環境変数の設定

以下の環境変数を設定（ターミナルで実行）：

```bash
export ASC_KEY_ID="XXXXXXXXX"  # キーID
export ASC_ISSUER_ID="YYYYYYYY-YYYY-YYYY-YYYY-YYYYYYYYYYYY"  # Issuer ID
export ASC_KEY_PATH="/Users/yuki/jitsuflow/fastlane/authkey/AuthKey_XXXXXXXXX.p8"
```

## 5. 実行

設定完了後、以下のコマンドでアップロードを開始：

```bash
# メタデータのみアップロード
fastlane ios metadata_only

# 完全なリリースフロー（ビルド + アップロード + 審査提出）
fastlane ios release
```

## セキュリティ注意事項

- APIキーファイル（.p8）は絶対にGitリポジトリにコミットしないでください
- APIキーは定期的にローテーションすることを推奨します
- 不要になったAPIキーは削除してください