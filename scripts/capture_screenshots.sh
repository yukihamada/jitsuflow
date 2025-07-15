#!/bin/bash
# シミュレーターでスクリーンショットを撮影

echo "📸 JitsuFlow スクリーンショット撮影スクリプト"
echo "============================================"

# スクリーンショット保存先
SCREENSHOT_DIR="/Users/yuki/jitsuflow/fastlane/screenshots/ja"
mkdir -p "$SCREENSHOT_DIR"

# デバイスID (iPhone 15 Pro Max)
DEVICE_ID="2DA413B3-5E50-4D01-9CC4-A135E7A350B1"

# アプリが起動するまで待機
echo "⏳ アプリの起動を待っています..."
sleep 5

# 1. スプラッシュ/ログイン画面
echo "📱 ログイン画面を撮影中..."
xcrun simctl io $DEVICE_ID screenshot "$SCREENSHOT_DIR/1_login.png"
sleep 2

# 2. ゲストログインをタップ（座標は概算）
echo "🔄 ゲストログインを実行中..."
xcrun simctl io $DEVICE_ID tap 645 1000
sleep 3

# 3. ホーム画面
echo "📱 ホーム画面を撮影中..."
xcrun simctl io $DEVICE_ID screenshot "$SCREENSHOT_DIR/2_home.png"
sleep 2

# 4. 予約画面へ移動（タブバーの予約アイコンをタップ）
echo "🔄 予約画面へ移動中..."
xcrun simctl io $DEVICE_ID tap 320 2700
sleep 2

echo "📱 予約画面を撮影中..."
xcrun simctl io $DEVICE_ID screenshot "$SCREENSHOT_DIR/3_booking.png"
sleep 2

# 5. プロフィール画面へ移動（タブバーのプロフィールアイコンをタップ）
echo "🔄 プロフィール画面へ移動中..."
xcrun simctl io $DEVICE_ID tap 970 2700
sleep 2

echo "📱 プロフィール画面を撮影中..."
xcrun simctl io $DEVICE_ID screenshot "$SCREENSHOT_DIR/4_profile.png"
sleep 2

# 6. 動画画面へ移動（タブバーの動画アイコンをタップ）
echo "🔄 動画画面へ移動中..."
xcrun simctl io $DEVICE_ID tap 645 2700
sleep 2

echo "📱 動画画面を撮影中..."
xcrun simctl io $DEVICE_ID screenshot "$SCREENSHOT_DIR/5_video.png"
sleep 2

echo "✅ スクリーンショット撮影完了！"
echo ""
echo "📁 保存先: $SCREENSHOT_DIR"
ls -la "$SCREENSHOT_DIR"/*.png

echo ""
echo "🔄 App Store用にリサイズ中..."

# ImageMagickでリサイズ（6.7インチ: 1290x2796）
for file in "$SCREENSHOT_DIR"/*.png; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        echo "  処理中: $filename"
        magick "$file" -resize 1290x2796! "$file"
    fi
done

echo ""
echo "✅ リサイズ完了！"
echo ""
echo "📤 次のステップ:"
echo "1. スクリーンショットを確認"
echo "2. fastlane ios upload_screenshots でアップロード"