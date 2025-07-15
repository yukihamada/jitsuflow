#!/bin/bash
# すべてのアイコンサイズを生成

echo "📱 全アイコンサイズ生成中..."

BASE="/Users/yuki/jitsuflow/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png"
ICON_DIR="/Users/yuki/jitsuflow/ios/Runner/Assets.xcassets/AppIcon.appiconset"

# iPhone用
magick "$BASE" -resize 40x40 "$ICON_DIR/Icon-App-20x20@2x.png"
magick "$BASE" -resize 60x60 "$ICON_DIR/Icon-App-20x20@3x.png"
magick "$BASE" -resize 58x58 "$ICON_DIR/Icon-App-29x29@2x.png"
magick "$BASE" -resize 87x87 "$ICON_DIR/Icon-App-29x29@3x.png"
magick "$BASE" -resize 80x80 "$ICON_DIR/Icon-App-40x40@2x.png"
magick "$BASE" -resize 120x120 "$ICON_DIR/Icon-App-40x40@3x.png"
magick "$BASE" -resize 120x120 "$ICON_DIR/Icon-App-60x60@2x.png"
magick "$BASE" -resize 180x180 "$ICON_DIR/Icon-App-60x60@3x.png"

# iPad用
magick "$BASE" -resize 20x20 "$ICON_DIR/Icon-App-20x20@1x.png"
magick "$BASE" -resize 29x29 "$ICON_DIR/Icon-App-29x29@1x.png"
magick "$BASE" -resize 40x40 "$ICON_DIR/Icon-App-40x40@1x.png"
magick "$BASE" -resize 76x76 "$ICON_DIR/Icon-App-76x76@1x.png"
magick "$BASE" -resize 152x152 "$ICON_DIR/Icon-App-76x76@2x.png"
magick "$BASE" -resize 167x167 "$ICON_DIR/Icon-App-83.5x83.5@2x.png"

echo "✅ 全サイズ生成完了！"