#!/bin/bash
# App Store Connect 対話型アップロードスクリプト

echo "📱 JitsuFlow App Store Connect 対話型アップロード"
echo "================================================"
echo ""
echo "⚠️  APIキーが設定されていないため、Apple IDでログインします"
echo ""
echo "必要な情報:"
echo "  • Apple ID: mail@yukihamada.jp"
echo "  • パスワード"
echo "  • 2段階認証コード（6桁）"
echo ""
echo "準備ができたら Enter キーを押してください..."
read

# Fastlaneパス
FASTLANE_PATH="/opt/homebrew/lib/ruby/gems/3.2.0/bin/fastlane"

# 環境変数設定
export SPACESHIP_SKIP_2FA_UPGRADE=1
export FASTLANE_DONT_STORE_PASSWORD=1

echo ""
echo "🚀 メタデータアップロードを開始します..."
echo ""
echo "📝 注意事項:"
echo "1. 2段階認証コードを求められたら、SMSまたは認証アプリの6桁コードを入力"
echo "2. 'sms' と入力すると、SMSでコードを受け取ることができます"
echo "3. セッションは30日間有効です"
echo ""

# Fastlane実行
cd /Users/yuki/jitsuflow
$FASTLANE_PATH ios metadata_only

echo ""
echo "✅ 処理が完了しました"
echo ""
echo "次回からセッションが保存されているため、パスワード入力は不要です。"