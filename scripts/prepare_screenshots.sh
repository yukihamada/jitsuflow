#!/bin/bash
# App Store用スクリーンショット準備スクリプト

set -e

echo "📸 JitsuFlow App Storeスクリーンショット準備"
echo "========================================="

# スクリーンショットディレクトリ
SCREENSHOT_DIR="/Users/yuki/jitsuflow/fastlane/screenshots/ja-JP"
SOURCE_DIR="/Users/yuki/jitsuflow/fastlane/screenshots/ja-JP"

# 必要なサイズ
# iPhone 6.7" (1290 x 2796) - iPhone 15 Pro Max等
# iPhone 6.5" (1284 x 2778) - iPhone 14 Plus等

echo "📱 既存のスクリーンショットを確認中..."

# 既存のスクリーンショットをコピー
if [ -f "$SOURCE_DIR/1_home.png" ]; then
    echo "✅ ホーム画面のスクリーンショットが見つかりました"
    cp "$SOURCE_DIR/1_home.png" "$SCREENSHOT_DIR/1_iphone6_7_home.png"
else
    echo "⚠️  ホーム画面のスクリーンショットがありません"
fi

if [ -f "$SOURCE_DIR/2_booking.png" ]; then
    echo "✅ 予約画面のスクリーンショットが見つかりました"
    cp "$SOURCE_DIR/2_booking.png" "$SCREENSHOT_DIR/2_iphone6_7_booking.png"
else
    echo "⚠️  予約画面のスクリーンショットがありません"
fi

if [ -f "$SOURCE_DIR/3_video.png" ]; then
    echo "✅ 動画画面のスクリーンショットが見つかりました"
    cp "$SOURCE_DIR/3_video.png" "$SCREENSHOT_DIR/3_iphone6_7_video.png"
else
    echo "⚠️  動画画面のスクリーンショットがありません"
fi

if [ -f "$SOURCE_DIR/4_profile.png" ]; then
    echo "✅ プロフィール画面のスクリーンショットが見つかりました"
    cp "$SOURCE_DIR/4_profile.png" "$SCREENSHOT_DIR/4_iphone6_7_profile.png"
else
    echo "⚠️  プロフィール画面のスクリーンショットがありません"
fi

echo ""
echo "📋 App Store Connect用メタデータ（コピペ用）"
echo "==========================================="
echo ""
echo "【アプリ名】"
echo "JitsuFlow"
echo ""
echo "【サブタイトル】"
echo "ブラジリアン柔術の練習と道場予約"
echo ""
echo "【プライマリカテゴリ】"
echo "スポーツ"
echo ""
echo "【セカンダリカテゴリ】"
echo "ヘルスケア/フィットネス"
echo ""
echo "【年齢制限レーティング】"
echo "4+ (暴力的表現なし)"
echo ""
echo "【価格】"
echo "無料（アプリ内課金あり）"
echo ""
echo "【アプリ内課金】"
echo "プレミアムプラン（月額）: ¥1,980"
echo "プレミアムプラン（年額）: ¥19,800"
echo ""
echo "【輸出コンプライアンス】"
echo "暗号化を使用していません（ITSAppUsesNonExemptEncryption = false）"
echo ""
echo "【著作権】"
echo "© 2025 Yuki Hamada"
echo ""
echo "【サポートURL】"
echo "https://jitsuflow.app/support.html"
echo ""
echo "【プライバシーポリシーURL】"
echo "https://jitsuflow.app/privacy.html"
echo ""
echo "【マーケティングURL】"
echo "https://jitsuflow.app"
echo ""

echo "✅ メタデータの準備が完了しました！"
echo ""
echo "📱 次のステップ："
echo "1. App Store Connectにログイン"
echo "2. 「マイApp」から「JitsuFlow」を選択"
echo "3. 「バージョンまたはプラットフォームを追加」をクリック"
echo "4. 上記のメタデータをコピペして入力"
echo "5. スクリーンショットをアップロード"
echo "6. 「審査へ提出」をクリック"