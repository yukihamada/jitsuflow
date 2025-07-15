# 📱 App Store Connect APIキー作成・ダウンロード完全ガイド

## 1. App Store Connectにログイン

1. ブラウザで以下のURLにアクセス:
   ```
   https://appstoreconnect.apple.com/
   ```

2. Apple IDでログイン
   - メールアドレス: `mail@yukihamada.jp`
   - パスワード: あなたのパスワード
   - 2段階認証コードを入力

## 2. ユーザーとアクセスページへ移動

1. ログイン後、画面上部のメニューから選択:
   - 「ユーザーとアクセス」をクリック
   
   または直接アクセス:
   ```
   https://appstoreconnect.apple.com/access/api
   ```

## 3. APIキータブを選択

1. 「ユーザーとアクセス」ページで:
   - 上部のタブから「キー」を選択
   - または左サイドバーの「統合」→「App Store Connect API」を選択

## 4. 新しいAPIキーを生成

### 新規作成の場合:

1. 「キーを生成」ボタン（＋アイコン）をクリック

2. キー情報を入力:
   - **名前**: `JitsuFlow Fastlane` または `JitsuFlow API Key`
   - **アクセス**: `App Manager` を選択
     - これにより、アプリのメタデータ更新、ビルドアップロード、審査提出が可能になります

3. 「生成」ボタンをクリック

### 既存のキー（088414）がある場合:

1. キーリストから `088414` を探す
2. キー名をクリックして詳細を表示

## 5. APIキーをダウンロード

1. キー生成後、以下の情報が表示されます:
   - **Key ID**: `088414`
   - **Issuer ID**: `408133`（既に設定済み）

2. 「APIキーをダウンロード」リンクをクリック
   - ファイル名: `AuthKey_088414.p8`
   - このファイルは**一度しかダウンロードできません**

3. ダウンロードフォルダに保存されたファイルを確認

## 6. ダウンロードしたファイルを移動

### macOSの場合:

1. Finderを開く
2. ダウンロードフォルダに移動
3. `AuthKey_088414.p8` ファイルを見つける
4. ファイルを以下の場所にコピー:
   ```
   /Users/yuki/jitsuflow/fastlane/authkey/
   ```

### ターミナルを使用する場合:

```bash
# ダウンロードフォルダから移動
mv ~/Downloads/AuthKey_088414.p8 /Users/yuki/jitsuflow/fastlane/authkey/

# 権限を設定（重要）
chmod 600 /Users/yuki/jitsuflow/fastlane/authkey/AuthKey_088414.p8
```

## 7. 設定の確認

ファイルが正しく配置されたか確認:

```bash
ls -la /Users/yuki/jitsuflow/fastlane/authkey/
```

以下のように表示されればOK:
```
-rw-------  1 yuki  staff  XXX  Date Time  AuthKey_088414.p8
```

## ⚠️ 重要な注意事項

1. **APIキーファイルは一度しかダウンロードできません**
   - 必ずバックアップを取ってください
   - 安全な場所に保管してください

2. **セキュリティ**
   - このファイルは秘密鍵です
   - Gitにコミットしないでください（.gitignoreに追加済み）
   - 他人と共有しないでください

3. **キーの権限**
   - `App Manager`権限があれば、アプリの管理に必要な全ての操作が可能です
   - より制限された権限が必要な場合は、個別に設定可能です

## 🚀 次のステップ

APIキーファイルを配置したら、以下のコマンドでApp Storeへのアップロードを実行できます:

```bash
# メタデータのみアップロード（最初のテスト）
make ios-metadata

# 審査に提出
make ios-release
```

## トラブルシューティング

### ダウンロードリンクが表示されない場合:
- 既にダウンロード済みの可能性があります
- 新しいキーを生成する必要があります

### Key IDが異なる場合:
- 新しく生成されたKey IDをFastfileで更新:
  ```bash
  # fastlane/Fastfileの8行目を編集
  key_id = "新しいKEY_ID"
  ```

### アクセス権限エラーの場合:
- アカウントの役割が「Admin」または「App Manager」であることを確認
- チームIDが正しく設定されているか確認