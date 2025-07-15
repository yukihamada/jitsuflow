#!/bin/bash
# App Store用アイコン生成スクリプト

echo "🎨 JitsuFlow アプリアイコン生成"
echo "=================================="

# アイコンディレクトリ
ICON_DIR="/Users/yuki/jitsuflow/ios/Runner/Assets.xcassets/AppIcon.appiconset"
mkdir -p "$ICON_DIR"

# ベースとなるアイコンを生成（1024x1024）
BASE_ICON="/tmp/jitsuflow_icon_base.png"

# ImageMagickでアイコンを生成
echo "📱 ベースアイコンを生成中..."

# JitsuFlowのアイコンデザイン（柔術の帯をイメージ）
magick -size 1024x1024 xc:white \
  -fill '#2C3E50' -draw "rectangle 0,0 1024,1024" \
  -fill '#E74C3C' -draw "rectangle 0,400 1024,624" \
  -fill white -font Arial-Bold -pointsize 120 \
  -gravity north -annotate +0+250 "JITSU" \
  -fill white -font Arial-Bold -pointsize 120 \
  -gravity south -annotate +0+250 "FLOW" \
  -fill white -font Arial -pointsize 60 \
  -gravity center -annotate +0+0 "柔術" \
  "$BASE_ICON"

# 必要なサイズのアイコンを生成
echo "🔄 各サイズのアイコンを生成中..."

# iPhone用アイコン
magick "$BASE_ICON" -resize 40x40 "$ICON_DIR/Icon-App-20x20@2x.png"
magick "$BASE_ICON" -resize 60x60 "$ICON_DIR/Icon-App-20x20@3x.png"
magick "$BASE_ICON" -resize 58x58 "$ICON_DIR/Icon-App-29x29@2x.png"
magick "$BASE_ICON" -resize 87x87 "$ICON_DIR/Icon-App-29x29@3x.png"
magick "$BASE_ICON" -resize 80x80 "$ICON_DIR/Icon-App-40x40@2x.png"
magick "$BASE_ICON" -resize 120x120 "$ICON_DIR/Icon-App-40x40@3x.png"
magick "$BASE_ICON" -resize 120x120 "$ICON_DIR/Icon-App-60x60@2x.png"
magick "$BASE_ICON" -resize 180x180 "$ICON_DIR/Icon-App-60x60@3x.png"

# iPad用アイコン
magick "$BASE_ICON" -resize 20x20 "$ICON_DIR/Icon-App-20x20@1x.png"
magick "$BASE_ICON" -resize 29x29 "$ICON_DIR/Icon-App-29x29@1x.png"
magick "$BASE_ICON" -resize 40x40 "$ICON_DIR/Icon-App-40x40@1x.png"
magick "$BASE_ICON" -resize 76x76 "$ICON_DIR/Icon-App-76x76@1x.png"
magick "$BASE_ICON" -resize 152x152 "$ICON_DIR/Icon-App-76x76@2x.png"
magick "$BASE_ICON" -resize 167x167 "$ICON_DIR/Icon-App-83.5x83.5@2x.png"

# App Store用アイコン（1024x1024）
magick "$BASE_ICON" -resize 1024x1024 "$ICON_DIR/Icon-App-1024x1024@1x.png"

# Contents.jsonを生成
cat > "$ICON_DIR/Contents.json" << EOF
{
  "images" : [
    {
      "size" : "20x20",
      "idiom" : "iphone",
      "filename" : "Icon-App-20x20@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "20x20",
      "idiom" : "iphone",
      "filename" : "Icon-App-20x20@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "29x29",
      "idiom" : "iphone",
      "filename" : "Icon-App-29x29@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "29x29",
      "idiom" : "iphone",
      "filename" : "Icon-App-29x29@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "40x40",
      "idiom" : "iphone",
      "filename" : "Icon-App-40x40@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "40x40",
      "idiom" : "iphone",
      "filename" : "Icon-App-40x40@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "60x60",
      "idiom" : "iphone",
      "filename" : "Icon-App-60x60@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "60x60",
      "idiom" : "iphone",
      "filename" : "Icon-App-60x60@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "20x20",
      "idiom" : "ipad",
      "filename" : "Icon-App-20x20@1x.png",
      "scale" : "1x"
    },
    {
      "size" : "20x20",
      "idiom" : "ipad",
      "filename" : "Icon-App-20x20@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "29x29",
      "idiom" : "ipad",
      "filename" : "Icon-App-29x29@1x.png",
      "scale" : "1x"
    },
    {
      "size" : "29x29",
      "idiom" : "ipad",
      "filename" : "Icon-App-29x29@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "40x40",
      "idiom" : "ipad",
      "filename" : "Icon-App-40x40@1x.png",
      "scale" : "1x"
    },
    {
      "size" : "40x40",
      "idiom" : "ipad",
      "filename" : "Icon-App-40x40@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "76x76",
      "idiom" : "ipad",
      "filename" : "Icon-App-76x76@1x.png",
      "scale" : "1x"
    },
    {
      "size" : "76x76",
      "idiom" : "ipad",
      "filename" : "Icon-App-76x76@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "83.5x83.5",
      "idiom" : "ipad",
      "filename" : "Icon-App-83.5x83.5@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "1024x1024",
      "idiom" : "ios-marketing",
      "filename" : "Icon-App-1024x1024@1x.png",
      "scale" : "1x"
    }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
EOF

# App Store Connect用のアイコンをコピー
echo "📤 App Store用アイコンを準備..."
mkdir -p "/Users/yuki/jitsuflow/fastlane/metadata"
cp "$ICON_DIR/Icon-App-1024x1024@1x.png" "/Users/yuki/jitsuflow/fastlane/metadata/app_icon.png"

echo "✅ アイコン生成完了！"
echo ""
echo "📁 生成されたアイコン:"
ls -la "$ICON_DIR"/*.png | wc -l
echo "個のアイコンファイル"
echo ""
echo "🎨 App Store用アイコン:"
echo "/Users/yuki/jitsuflow/fastlane/metadata/app_icon.png"
echo ""
echo "次のステップ:"
echo "1. flutter build ipa でアプリを再ビルド"
echo "2. fastlane でアイコンをアップロード"