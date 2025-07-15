#!/bin/bash
# TestFlight自動アップロードスクリプト

set -e

# 環境変数チェック
if [ -z "$APPLE_ID" ] || [ -z "$APP_SPECIFIC_PASSWORD" ]; then
    echo "Error: APPLE_ID と APP_SPECIFIC_PASSWORD の環境変数を設定してください"
    echo "例: export APPLE_ID='your-email@example.com'"
    echo "例: export APP_SPECIFIC_PASSWORD='xxxx-xxxx-xxxx-xxxx'"
    exit 1
fi

# 現在のビルド番号を取得
CURRENT_VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //')
CURRENT_BUILD=$(echo $CURRENT_VERSION | sed 's/.*+//')
NEW_BUILD=$((CURRENT_BUILD + 1))
VERSION_NUMBER=$(echo $CURRENT_VERSION | sed 's/+.*//')

echo "📱 JitsuFlow TestFlightアップロード"
echo "================================"
echo "現在のバージョン: $VERSION_NUMBER+$CURRENT_BUILD"
echo "新しいバージョン: $VERSION_NUMBER+$NEW_BUILD"
echo ""

# pubspec.yamlを更新
echo "📝 ビルド番号を更新中..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i "" "s/version: .*/version: $VERSION_NUMBER+$NEW_BUILD/" pubspec.yaml
else
    # Linux
    sed -i "s/version: .*/version: $VERSION_NUMBER+$NEW_BUILD/" pubspec.yaml
fi

# クリーンビルド
echo "🧹 プロジェクトをクリーンアップ中..."
flutter clean

# パッケージの取得
echo "📦 パッケージを取得中..."
flutter pub get

# IPAビルド
echo "🏗️  IPAファイルをビルド中..."
flutter build ipa --release

# ビルド成功確認
if [ ! -f "build/ios/ipa/JitsuFlow.ipa" ]; then
    echo "❌ エラー: IPAファイルが見つかりません"
    exit 1
fi

# ファイルサイズ表示
IPA_SIZE=$(du -h build/ios/ipa/JitsuFlow.ipa | cut -f1)
echo "✅ IPAファイルビルド完了 (サイズ: $IPA_SIZE)"

# TestFlightへアップロード
echo "🚀 TestFlightへアップロード中..."
xcrun altool --upload-app \
    -f build/ios/ipa/JitsuFlow.ipa \
    -t ios \
    -u "$APPLE_ID" \
    -p "$APP_SPECIFIC_PASSWORD" \
    --verbose

if [ $? -eq 0 ]; then
    echo "✅ TestFlightへのアップロードが完了しました！"
    echo ""
    echo "📱 App Store Connectで以下を確認してください:"
    echo "   1. ビルドの処理状況（15-30分かかります）"
    echo "   2. テスターへの配信設定"
    echo "   3. テスト情報の入力"
    echo ""
    echo "🎉 バージョン $VERSION_NUMBER ($NEW_BUILD) のアップロードが成功しました！"
else
    echo "❌ アップロードに失敗しました"
    
    # ビルド番号を元に戻す
    echo "📝 ビルド番号を元に戻しています..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i "" "s/version: .*/version: $VERSION_NUMBER+$CURRENT_BUILD/" pubspec.yaml
    else
        sed -i "s/version: .*/version: $VERSION_NUMBER+$CURRENT_BUILD/" pubspec.yaml
    fi
    
    exit 1
fi