#!/bin/bash

# JitsuFlow iOS App Store自動アップロードスクリプト
# 使用方法: ./scripts/ios_appstore_upload.sh [metadata|beta|release]

set -e  # エラー時に停止

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ログ関数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 引数チェック
if [ $# -eq 0 ]; then
    echo "使用方法: $0 [metadata|beta|release]"
    echo ""
    echo "  metadata  - メタデータとスクリーンショットのみアップロード"
    echo "  beta      - TestFlightにビルドをアップロード"
    echo "  release   - 完全なApp Store提出フロー"
    exit 1
fi

ACTION=$1

# 必要な環境変数チェック
check_env_vars() {
    log_info "環境変数をチェック中..."
    
    if [ -z "$ASC_KEY_ID" ] || [ -z "$ASC_ISSUER_ID" ] || [ -z "$ASC_KEY_PATH" ]; then
        log_warning "App Store Connect API Keyの環境変数が設定されていません"
        log_info "認証のため、Apple IDでのログインが必要になります"
        return 1
    else
        log_success "App Store Connect API Key環境変数が設定されています"
        
        # APIキーファイルの存在確認
        if [ ! -f "$ASC_KEY_PATH" ]; then
            log_error "APIキーファイルが見つかりません: $ASC_KEY_PATH"
            exit 1
        fi
        
        return 0
    fi
}

# Fastlaneインストール確認
check_fastlane() {
    log_info "Fastlaneのインストールをチェック中..."
    
    export PATH="/opt/homebrew/lib/ruby/gems/3.2.0/bin:$PATH"
    
    if ! command -v fastlane &> /dev/null; then
        log_error "Fastlaneがインストールされていません"
        log_info "インストール中..."
        gem install fastlane
        log_success "Fastlaneをインストールしました"
    else
        log_success "Fastlane is installed: $(fastlane --version | grep 'fastlane')"
    fi
}

# プロジェクトディレクトリに移動
cd "$(dirname "$0")/.."

# チェック実行
check_fastlane
ENV_CHECK=$(check_env_vars && echo "true" || echo "false")

# PATHを設定
export PATH="/opt/homebrew/lib/ruby/gems/3.2.0/bin:$PATH"

case $ACTION in
    "metadata")
        log_info "メタデータとスクリーンショットをApp Store Connectにアップロード中..."
        fastlane ios metadata_only
        log_success "メタデータのアップロードが完了しました！"
        ;;
    
    "beta")
        log_info "TestFlightにビルドをアップロード中..."
        log_warning "注意: このアクションはXcodeでのビルドとコード署名が必要です"
        fastlane ios beta
        log_success "TestFlightへのアップロードが完了しました！"
        ;;
    
    "release")
        log_info "完全なApp Store提出フローを開始中..."
        log_warning "注意: このアクションはXcodeでのビルドとコード署名が必要です"
        fastlane ios release
        log_success "App Storeへの提出が完了しました！"
        ;;
    
    *)
        log_error "無効なアクション: $ACTION"
        echo "使用可能なアクション: metadata, beta, release"
        exit 1
        ;;
esac

log_success "🎉 処理が正常に完了しました！"

# 次のステップを表示
echo ""
log_info "次のステップ:"
case $ACTION in
    "metadata")
        echo "1. App Store Connectで情報を確認してください"
        echo "2. ビルドをアップロードするには: $0 beta"
        ;;
    "beta")
        echo "1. TestFlightでビルドを確認してください"
        echo "2. 審査に提出するには: $0 release"
        ;;
    "release")
        echo "1. App Store Connectで審査ステータスを確認してください"
        echo "2. 審査完了後、アプリが公開されます"
        ;;
esac

if [ "$ENV_CHECK" = "false" ]; then
    echo ""
    log_warning "自動化のため、App Store Connect API Keyの設定を推奨します:"
    echo "詳細: fastlane/API_KEY_SETUP.md を参照してください"
fi