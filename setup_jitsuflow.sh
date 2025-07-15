#!/bin/bash

set -e

echo "🟢 JitsuFlow開発環境セットアップ開始..."

# プロジェクト名
PROJECT="jitsuflow"

# Claude初期化
claude init $PROJECT
cd $PROJECT

# claude.json 作成
cat > claude.json << EOF
{
  "project": "jitsuflow",
  "description": "ブラジリアン柔術トレーニング＆道場予約アプリ",
  "framework": {
    "frontend": "flutter",
    "seo_framework": "jaspr",
    "testing_framework": "playwright"
  },
  "infrastructure": {
    "cloudflare": {
      "workers": { "enabled": true, "script_name": "jitsuflow_worker", "routes": ["jitsuflow.app/api/*"] },
      "r2": { "enabled": true, "bucket": "jitsuflow-assets" },
      "d1": { "enabled": true, "database_name": "jitsuflow_db" }
    }
  },
  "claude_code": {
    "parallel_execution": { "enabled": true, "max_concurrency": 8 },
    "tasks": {
      "user_registration": { "automation": true },
      "training_schedule": { "automation": true },
      "dojo_booking": { "automation": true },
      "video_upload": { "automation": true },
      "video_streaming": { "automation": true },
      "notification_service": { "automation": true },
      "subscription_payment": { "automation": true, "provider": "stripe" },
      "realtime_chat": { "automation": true }
    },
    "auto_test": { "enabled": true, "framework": "playwright" },
    "seo_optimization": { "enabled": true, "ssr": true, "framework": "jaspr" },
    "analytics": { "enabled": true, "provider": "cloudflare" },
    "deployment": { "auto_deploy": true, "approval_required": false, "notification_channel": "slack" }
  },
  "cost_management": {
    "monthly_budget_usd": 500,
    "alert_threshold_percent": 80,
    "notification_channel": "email"
  }
}
EOF

echo "🟢 Claude Code設定ファイル生成完了..."

# Cloudflareインフラ設定（Workers, D1, R2）
claude infra deploy

# Flutterアプリ作成
flutter create .
flutter pub add jaspr jaspr_flutter supabase_flutter stripe_sdk intl

# Playwright設定
playwright install chromium --with-deps

# SQLiteデータベース設定（D1）
claude d1 create --database=jitsuflow_db

# Cloudflare R2バケット設定
claude r2 create --bucket=jitsuflow-assets

# Stripe設定（課金用）
stripe login

# Supabase（ローカルOSS版）初期設定（認証・リアルタイム）
supabase init
supabase start

echo "🟢 開発環境セットアップ完了 🎉"
