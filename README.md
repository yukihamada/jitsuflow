# JitsuFlow 🥋

[![Flutter Version](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Web%20|%20iOS%20|%20Android-lightgrey.svg)](https://flutter.dev)

**JitsuFlow** は、ブラジリアン柔術の練習・道場運営を効率化する包括的なプラットフォームです。

## ✨ 主要機能

### 🏠 一般ユーザー向け機能
- **予約システム** - クラスの予約・キャンセル・キャンセル待ち
- **技術動画ライブラリ** - プレミアム動画コンテンツ
- **スキル評価** - 個人の技術レベル追跡
- **月額課金** - Stripe統合によるサブスクリプション

### 👨‍🏫 インストラクター専用機能
- **ダッシュボード** - 実績・スケジュール・収入の一覧表示
- **給与管理** - 月次給与明細・年間実績確認
- **生徒評価** - 生徒からのフィードバック確認
- **クラス管理** - 出席確認・クラス報告

### 🏪 道場運営機能
- **POSシステム** - 物販・レンタル商品の販売
- **決済統合** - Stripe POS・クレジットカード決済
- **在庫管理** - 商品・レンタル用品の管理
- **経営分析** - 売上・利益・KPI分析
- **スパーリング録画** - 練習動画の記録・管理

### 🎯 高度な機能
- **定員管理** - クラスの最大収容人数制御
- **キャンセル待ち** - 満席時の自動ウェイトリスト
- **リアルタイム通知** - 予約確定・キャンセル通知
- **多道場対応** - 複数拠点の一元管理

## 🚀 技術スタック

### フロントエンド
- **Flutter** - クロスプラットフォーム開発
- **BLoC** - 状態管理パターン
- **Material Design 3** - モダンなUI/UX

### バックエンド
- **Cloudflare Workers** - サーバーレスAPI
- **Cloudflare D1** - SQLデータベース
- **Cloudflare R2** - オブジェクトストレージ

### 決済・統合サービス
- **Stripe** - 決済処理・サブスクリプション
- **Google Chat Webhook** - 通知システム
- **ReSend** - メール配信

### 開発・運用
- **GitHub Actions** - CI/CDパイプライン
- **Docker** - コンテナ化
- **Claude Code** - AI支援開発

## 📱 対応プラットフォーム

- 🌐 **Web** (Chrome, Safari, Firefox, Edge)
- 📱 **iOS** (iPhone, iPad)
- 🤖 **Android** (スマートフォン, タブレット)
- 💻 **macOS** (デスクトップアプリ)

## 🔧 セットアップ

### 必要な環境
- Flutter 3.0+
- Dart 3.0+
- Node.js 18+ (Cloudflare Workers用)

### インストール

```bash
# リポジトリをクローン
git clone https://github.com/your-org/jitsuflow.git
cd jitsuflow

# 依存関係をインストール
flutter pub get

# コード生成を実行
flutter packages pub run build_runner build --delete-conflicting-outputs

# 開発サーバーを起動
flutter run -d chrome
```

## 🌐 デプロイ

### Web版デプロイ
```bash
# Webビルド
flutter build web --release

# Cloudflare Pagesにデプロイ
npx wrangler pages publish build/web
```

### モバイルアプリ
```bash
# iOS
flutter build ios --release

# Android
flutter build apk --release
```

### 📱 App Store Connect アップロード

JitsuFlowアプリをApp Store Connectに自動でアップロードできます：

```bash
# App Store Connect API Keyを設定
export ASC_KEY_ID="YOUR_KEY_ID"
export ASC_ISSUER_ID="YOUR_ISSUER_ID"
export ASC_KEY_PATH="/path/to/AuthKey_XXXXXXXXX.p8"

# メタデータとスクリーンショットをアップロード
make ios-metadata

# TestFlightにアップロード
make ios-beta

# 審査に提出
make ios-release
```

詳細な手順：
- **APIキー設定**: `fastlane/API_KEY_SETUP.md`
- **完全ガイド**: `APP_STORE_UPLOAD_GUIDE.md`

## 📋 API仕様

### 主要エンドポイント

#### 認証
- `POST /api/auth/login` - ログイン
- `POST /api/auth/register` - ユーザー登録
- `DELETE /api/auth/logout` - ログアウト

#### 予約管理
- `GET /api/bookings` - 予約一覧取得
- `POST /api/bookings` - 新規予約作成
- `PATCH /api/bookings/:id/cancel` - 予約キャンセル
- `GET /api/bookings/waitlist` - キャンセル待ち一覧

#### 決済
- `POST /api/payments/subscription` - サブスクリプション作成
- `PUT /api/payments/subscription/:id` - プラン変更
- `POST /api/dojo-mode/:dojoId/payment-intent` - POS決済

#### インストラクター
- `GET /api/instructors/:id` - インストラクター詳細
- `GET /api/instructors/:id/payroll` - 給与明細
- `GET /api/instructors/:id/ratings` - 評価一覧

#### 経営分析
- `GET /api/analytics/revenue` - 売上分析
- `GET /api/analytics/kpi` - KPI指標
- `GET /api/analytics/trends` - トレンド分析

## 🧪 テスト

```bash
# 単体テスト実行
flutter test

# ウィジェットテスト実行
flutter test test/widget_test.dart

# E2Eテスト実行
flutter drive --target=test_driver/app.dart
```

## 📊 主要画面

### ホーム画面
- ウェルカムカード
- クイックアクション（予約・動画・インストラクター・道場モード）
- スキル評価チャート

### インストラクターダッシュボード
- 今月の実績サマリー（クラス数・生徒数・評価・収入）
- 今後のクラススケジュール
- 給与情報（今月・先月）
- 最近の生徒評価

### 道場モード
- POS販売システム
- レンタル管理
- スパーリング録画
- 売上分析

## 🤝 コントリビューション

1. フォークしてブランチを作成
2. 機能を実装・テストを追加
3. プルリクエストを作成

### 開発ガイドライン
- **BLoC** パターンに従った状態管理
- **Material Design 3** に準拠したデザイン
- **日本語コメント** で可読性向上
- **包括的なテスト** 記述

## 📄 ライセンス

このプロジェクトは MIT ライセンスの下で公開されています。詳細は [LICENSE](LICENSE) ファイルをご覧ください。

## 📞 サポート

- 🐛 **バグ報告**: [GitHub Issues](https://github.com/your-org/jitsuflow/issues)
- 💡 **機能要望**: [GitHub Discussions](https://github.com/your-org/jitsuflow/discussions)
- 📧 **お問い合わせ**: contact@jitsuflow.com

---

**JitsuFlow** - ブラジリアン柔術コミュニティを技術で支える 🥋✨
