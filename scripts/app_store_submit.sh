#!/bin/bash
# App Store提出用スクリプト

set -e

echo "🚀 JitsuFlow App Store提出準備"
echo "===================================="
echo ""

# カラー定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# チェックリスト表示
echo "📋 提出前チェックリスト"
echo "------------------------"
echo ""

# TestFlightビルド確認
echo -e "${YELLOW}1. TestFlightビルド${NC}"
echo "   ビルド番号: 1.0.0 (2)"
echo "   UUID: 09b24354-e03b-40e4-98fa-c6a40e008c5e"
echo -e "   ステータス: ${GREEN}✓ アップロード済み${NC}"
echo ""

# Webページ確認
echo -e "${YELLOW}2. 必須Webページ${NC}"
URLS=(
    "https://jitsuflow.app"
    "https://jitsuflow.app/support.html"
    "https://jitsuflow.app/privacy.html"
    "https://jitsuflow.app/terms.html"
)

for url in "${URLS[@]}"; do
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200"; then
        echo -e "   ${GREEN}✓${NC} $url"
    else
        echo -e "   ${RED}✗${NC} $url (アクセスできません)"
    fi
done
echo ""

# メタデータファイル確認
echo -e "${YELLOW}3. メタデータファイル${NC}"
METADATA_FILES=(
    "fastlane/metadata/ja-JP/description.txt"
    "fastlane/metadata/ja-JP/keywords.txt"
    "fastlane/metadata/ja-JP/name.txt"
    "fastlane/metadata/ja-JP/subtitle.txt"
    "fastlane/metadata/ja-JP/promotional_text.txt"
    "fastlane/metadata/ja-JP/release_notes.txt"
)

for file in "${METADATA_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "   ${GREEN}✓${NC} $file"
    else
        echo -e "   ${RED}✗${NC} $file (ファイルが見つかりません)"
    fi
done
echo ""

# Info.plist権限確認
echo -e "${YELLOW}4. アプリ権限設定${NC}"
if grep -q "NSCameraUsageDescription" ios/Runner/Info.plist; then
    echo -e "   ${GREEN}✓${NC} カメラ使用許可"
fi
if grep -q "NSPhotoLibraryUsageDescription" ios/Runner/Info.plist; then
    echo -e "   ${GREEN}✓${NC} 写真ライブラリ使用許可"
fi
if grep -q "NSLocationWhenInUseUsageDescription" ios/Runner/Info.plist; then
    echo -e "   ${GREEN}✓${NC} 位置情報使用許可"
fi
if grep -q "ITSAppUsesNonExemptEncryption" ios/Runner/Info.plist; then
    echo -e "   ${GREEN}✓${NC} 暗号化設定"
fi
echo ""

# App Store Connect URL生成
echo "🔗 App Store Connect リンク"
echo "----------------------------"
echo ""
echo "1. アプリ管理ページ:"
echo "   https://appstoreconnect.apple.com/apps"
echo ""
echo "2. TestFlightページ:"
echo "   https://appstoreconnect.apple.com/apps/[APP_ID]/testflight/ios"
echo ""
echo "3. アプリ情報編集:"
echo "   https://appstoreconnect.apple.com/apps/[APP_ID]/appstore/ios/version/inflight"
echo ""

# コピペ用データ表示
echo "📝 コピペ用データ"
echo "-----------------"
echo ""
echo "【基本情報をクリップボードにコピー】"
echo ""

# 基本情報を一時ファイルに保存
cat > /tmp/jitsuflow_appstore_info.txt << EOF
アプリ名: JitsuFlow
サブタイトル: ブラジリアン柔術の練習と道場予約
プライマリカテゴリ: スポーツ
セカンダリカテゴリ: ヘルスケア/フィットネス
価格: 無料
著作権: © 2025 Yuki Hamada
年齢制限: 4+
EOF

# macOSの場合、クリップボードにコピー
if [[ "$OSTYPE" == "darwin"* ]]; then
    cat /tmp/jitsuflow_appstore_info.txt | pbcopy
    echo -e "${GREEN}✓ 基本情報をクリップボードにコピーしました${NC}"
else
    cat /tmp/jitsuflow_appstore_info.txt
fi

echo ""
echo "📱 次のステップ:"
echo "1. App Store Connectにログイン"
echo "2. 上記の情報をコピペして入力"
echo "3. スクリーンショットをアップロード"
echo "4. ビルド1.0.0 (2)を選択"
echo "5. 審査へ提出"
echo ""
echo "詳細はAPP_STORE_CHECKLIST.mdを参照してください。"