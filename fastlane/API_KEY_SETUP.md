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
- `.gitignore` で `fastlane/authkey/*.p8` と `.env.appstore` を除外しています
- APIキーは定期的にローテーションすることを推奨します
- 不要になったAPIキーは削除してください

## キーのローテーション手順

過去にコミットされてしまった、流出が疑われる、または定期ローテーションを行う場合：

### 1. App Store Connect で旧キーを失効させる

1. https://appstoreconnect.apple.com/access/api を開く
2. 対象キー（例：`AuthKey_TYAN6W54AG.p8`）の「Revoke」をクリック
3. 失効を確定（即座に当該キーでの API アクセスは拒否されます）

### 2. 新しいキーを発行

このドキュメントの「1. App Store Connect APIキーの作成」「2. APIキーファイルのダウンロード」に従って新規発行。
キー名は `JitsuFlow Fastlane API Key (YYYY-MM-DD)` のように発行日を付けると追跡しやすい。

### 3. 新キーを安全に配置する

```bash
# ローカル：fastlane/authkey/ 配下に置く（.gitignore で除外済み）
mv ~/Downloads/AuthKey_NEWKEYID.p8 fastlane/authkey/

# 環境変数を更新
export ASC_KEY_ID="NEWKEYID"
export ASC_KEY_PATH="$(pwd)/fastlane/authkey/AuthKey_NEWKEYID.p8"
```

### 4. CI/CD のシークレットを更新

GitHub リポジトリ設定の Secrets を更新：

- `ASC_KEY_ID` — 新しいキー ID
- `ASC_KEY_CONTENT` — `.p8` ファイルの中身（base64 化推奨）
- `ASC_ISSUER_ID` — 変更がなければそのまま

### 5. `Fastfile` のハードコード値を更新

`fastlane/Fastfile` 内に旧 key_id がハードコードされている場合は新しい値に置換してコミット。

### 6. 既にコミット済みの旧 .p8 を Git 履歴から除去（流出時のみ）

⚠️ **履歴改変は破壊的操作。チーム全員に事前共有してから実施。**

```bash
# 例: git filter-repo を使う場合（推奨）
git filter-repo --path fastlane/authkey/AuthKey_OLDKEYID.p8 --invert-paths

# その後 force-push
git push origin --force --all
git push origin --force --tags
```

履歴から消しても **GitHub のキャッシュ・フォーク・クローンには残る** ため、Step 1 のキー失効が本質的なリスク低減策です。履歴からの除去は補助的な対策と捉えてください。