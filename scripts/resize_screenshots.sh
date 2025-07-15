#!/bin/bash
# App Store用スクリーンショットリサイズスクリプト

echo "📸 スクリーンショットをApp Store用にリサイズ"
echo "============================================"

# 必要なサイズ（iPhone）
# 6.7" - 1290x2796 (iPhone 15 Pro Max)
# 6.5" - 1284x2778 (iPhone 14 Plus) 
# 5.5" - 1242x2208 (iPhone 8 Plus)

# ImageMagickがインストールされているか確認
if ! command -v convert &> /dev/null; then
    echo "⚠️  ImageMagickが必要です。インストールしてください:"
    echo "brew install imagemagick"
    exit 1
fi

# スクリーンショットディレクトリ
SCREENSHOT_DIR="/Users/yuki/jitsuflow/fastlane/screenshots/ja"
cd "$SCREENSHOT_DIR"

# バックアップディレクトリ作成
mkdir -p originals
echo "📁 オリジナルファイルをバックアップ..."

# オリジナルをバックアップ
for file in *.png; do
    if [ -f "$file" ]; then
        cp "$file" "originals/$file"
    fi
done

echo "🔄 スクリーンショットをリサイズ..."

# 6.7インチ用（1290x2796）にリサイズ
for file in *.png; do
    if [ -f "$file" ]; then
        echo "  処理中: $file"
        # アスペクト比を保持しながらリサイズ
        convert "$file" -resize 1290x2796! "${file%.png}_67inch.png"
    fi
done

# 6.5インチ用（1284x2778）にリサイズ
for file in originals/*.png; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        convert "$file" -resize 1284x2778! "${filename%.png}_65inch.png"
    fi
done

# 5.5インチ用（1242x2208）にリサイズ
for file in originals/*.png; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        convert "$file" -resize 1242x2208! "${filename%.png}_55inch.png"
    fi
done

# メインのスクリーンショットを6.7インチ版に置き換え
echo "📱 メインファイルを更新..."
for file in *_67inch.png; do
    if [ -f "$file" ]; then
        base_name="${file%_67inch.png}.png"
        mv "$file" "$base_name"
    fi
done

echo "✅ リサイズ完了！"
echo ""
echo "生成されたファイル:"
ls -la *.png | grep -v originals

echo ""
echo "📤 次のステップ: make ios-metadata を実行"