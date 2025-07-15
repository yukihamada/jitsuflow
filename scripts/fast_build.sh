#!/bin/bash
# 高速ビルド用スクリプト（開発時用）

set -e

echo "⚡ Flutter高速ビルド（開発用）"
echo "=============================="

# 環境変数設定
export FLUTTER_BUILD_MODE=debug
export COCOAPODS_DISABLE_STATS=true

# オプション解析
BUILD_TYPE="debug"
PLATFORM="ios"

while [[ $# -gt 0 ]]; do
    case $1 in
        --release)
            BUILD_TYPE="release"
            shift
            ;;
        --android)
            PLATFORM="android"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "📱 プラットフォーム: $PLATFORM"
echo "🏗️  ビルドタイプ: $BUILD_TYPE"
echo ""

if [ "$PLATFORM" = "ios" ]; then
    # iOS高速ビルド設定
    echo "🍎 iOS向け最適化を適用中..."
    
    # Xcodeの派生データをクリア（必要な場合のみ）
    if [ "$1" = "--clean" ]; then
        echo "🧹 派生データをクリア中..."
        rm -rf ~/Library/Developer/Xcode/DerivedData/*
    fi
    
    # CocoaPodsの最適化
    cd ios
    if [ -f "Podfile.lock" ]; then
        echo "📦 Pod依存関係を確認中..."
        pod install --deployment
    fi
    cd ..
    
    if [ "$BUILD_TYPE" = "debug" ]; then
        # デバッグビルド（高速）
        flutter build ios --debug --simulator \
            --dart-define=FLUTTER_BUILD_MODE=debug \
            --no-codesign
    else
        # リリースビルド（最適化）
        flutter build ipa --release \
            --dart-define=FLUTTER_BUILD_MODE=release
    fi
    
elif [ "$PLATFORM" = "android" ]; then
    # Android高速ビルド設定
    echo "🤖 Android向け最適化を適用中..."
    
    if [ "$BUILD_TYPE" = "debug" ]; then
        # デバッグビルド（高速）
        flutter build apk --debug \
            --dart-define=FLUTTER_BUILD_MODE=debug
    else
        # リリースビルド（最適化）
        flutter build apk --release \
            --dart-define=FLUTTER_BUILD_MODE=release \
            --obfuscate \
            --split-debug-info=build/debug-info
    fi
fi

echo ""
echo "✅ ビルド完了！"