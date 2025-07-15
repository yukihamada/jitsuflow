#!/bin/bash
# APIキー設定確認スクリプト

echo "🔍 App Store Connect APIキー設定確認"
echo "====================================="
echo ""

# カラー定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# APIキーファイルのパス
API_KEY_PATH="/Users/yuki/jitsuflow/fastlane/authkey/AuthKey_088414.p8"

# 1. ディレクトリの確認
echo "1. authkeyディレクトリの確認:"
if [ -d "/Users/yuki/jitsuflow/fastlane/authkey" ]; then
    echo -e "   ${GREEN}✓${NC} ディレクトリが存在します"
else
    echo -e "   ${RED}✗${NC} ディレクトリが存在しません"
    echo "   → mkdir -p /Users/yuki/jitsuflow/fastlane/authkey を実行してください"
fi
echo ""

# 2. APIキーファイルの確認
echo "2. APIキーファイルの確認:"
if [ -f "$API_KEY_PATH" ]; then
    echo -e "   ${GREEN}✓${NC} AuthKey_088414.p8 が存在します"
    
    # ファイルサイズ確認
    FILE_SIZE=$(stat -f%z "$API_KEY_PATH" 2>/dev/null || stat -c%s "$API_KEY_PATH" 2>/dev/null)
    echo "   ファイルサイズ: ${FILE_SIZE} bytes"
    
    # 権限確認
    FILE_PERMS=$(ls -la "$API_KEY_PATH" | awk '{print $1}')
    echo "   権限: ${FILE_PERMS}"
    
    # 内容の簡易確認（最初の行のみ）
    if head -n 1 "$API_KEY_PATH" | grep -q "BEGIN PRIVATE KEY"; then
        echo -e "   ${GREEN}✓${NC} 有効なプライベートキーファイルです"
    else
        echo -e "   ${YELLOW}⚠️${NC} ファイル形式を確認してください"
    fi
else
    echo -e "   ${RED}✗${NC} AuthKey_088414.p8 が見つかりません"
    echo ""
    echo "   📥 ダウンロード手順:"
    echo "   1. https://appstoreconnect.apple.com/ にログイン"
    echo "   2. ユーザーとアクセス → キー"
    echo "   3. Key ID 088414 のキーをダウンロード"
    echo "   4. ダウンロードしたファイルを以下に配置:"
    echo "      $API_KEY_PATH"
fi
echo ""

# 3. Fastfile設定の確認
echo "3. Fastfile設定の確認:"
if grep -q "key_id = \"088414\"" /Users/yuki/jitsuflow/fastlane/Fastfile; then
    echo -e "   ${GREEN}✓${NC} Key ID: 088414 が設定されています"
else
    echo -e "   ${RED}✗${NC} Key IDが設定されていません"
fi

if grep -q "issuer_id = \"408133\"" /Users/yuki/jitsuflow/fastlane/Fastfile; then
    echo -e "   ${GREEN}✓${NC} Issuer ID: 408133 が設定されています"
else
    echo -e "   ${RED}✗${NC} Issuer IDが設定されていません"
fi
echo ""

# 4. 実行可能なコマンド
echo "4. 実行可能なコマンド:"
if [ -f "$API_KEY_PATH" ]; then
    echo -e "   ${GREEN}✓${NC} APIキーが設定されているため、以下のコマンドが使用可能です:"
    echo ""
    echo "   make ios-metadata    # メタデータのみアップロード"
    echo "   make ios-beta        # TestFlightへアップロード"
    echo "   make ios-release     # 審査に提出"
else
    echo -e "   ${YELLOW}⚠️${NC} APIキーを設定してから実行してください"
fi
echo ""

# 5. ダウンロードフォルダの確認（ヒント）
echo "5. ヒント: ダウンロードフォルダの確認"
if ls ~/Downloads/AuthKey_*.p8 2>/dev/null | head -n 1 > /dev/null; then
    echo -e "   ${YELLOW}💡${NC} ダウンロードフォルダにAPIキーファイルが見つかりました:"
    ls ~/Downloads/AuthKey_*.p8
    echo ""
    echo "   以下のコマンドで移動できます:"
    echo "   mv ~/Downloads/AuthKey_*.p8 $API_KEY_PATH"
fi