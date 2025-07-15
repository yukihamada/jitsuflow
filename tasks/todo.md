# JitsuFlow 開発作業計画

## 🔥 課題分析

### 目的
ブラジリアン柔術の練習・道場運営を最も効率的に行えるプラットフォームを構築し、以下の目標を達成する：
- 道場予約にかかる時間を75%以上短縮
- プレミアム課金コンテンツの継続率85%以上
- 月間アクティブユーザー(MAU)を安定的に増加

### 技術スタック（Cloudflare特化）
- **フロントエンド**: Flutter + Jaspr（SSR・SEO最適化）
- **バックエンド**: Cloudflare Workers + R2 + D1
- **課金**: Stripe
- **テスト**: Playwright
- **CI/CD**: GitHub Actions

## 📋 作業計画（CLI実行可能なToDoリスト）

### Phase 1: 基盤構築
- [ ] Flutter プロジェクトの初期化
  - [ ] `flutter create . --org app.jitsuflow --project-name jitsuflow --platforms=ios,android,web`
  - [ ] 基本依存関係の追加（jaspr, stripe_sdk）
- [ ] Cloudflare Workers 開発環境セットアップ
  - [ ] wrangler.toml 設定ファイル作成
  - [ ] D1データベース作成・マイグレーション
  - [ ] R2バケット作成・設定
- [ ] 開発環境設定
  - [ ] Makefile作成（開発コマンド自動化）
  - [ ] .env環境変数設定
  - [ ] Docker環境設定（オプション）

### Phase 2: 認証システム
- [ ] ユーザー認証機能（Cloudflare D1ベース）
  - [ ] ユーザー登録API（Workers）
  - [ ] ログイン・ログアウト機能
  - [ ] JWT トークン管理
  - [ ] Flutter認証UI実装

### Phase 3: 道場予約システム
- [ ] 道場予約機能
  - [ ] 予約データベース設計（D1）
  - [ ] 予約作成・編集・削除API
  - [ ] 時間枠管理機能
  - [ ] Flutter予約UI実装

### Phase 4: 動画機能
- [ ] 動画アップロード・管理
  - [ ] R2ストレージ統合
  - [ ] 動画メタデータ管理（D1）
  - [ ] 動画プレイヤー実装
  - [ ] プレミアム動画の制限機能

### Phase 5: 課金システム
- [ ] Stripe課金システム統合
  - [ ] 課金プラン設定
  - [ ] 決済フロー実装
  - [ ] Webhook処理
  - [ ] 継続課金管理

### Phase 6: 最適化・テスト
- [ ] E2Eテスト環境構築（Playwright）
  - [ ] 主要機能のテストケース作成
  - [ ] 自動テスト実行環境
- [ ] SEO最適化（Jaspr）
  - [ ] SSR設定
  - [ ] メタタグ最適化
- [ ] パフォーマンス最適化
  - [ ] 画像・動画最適化
  - [ ] CDN設定

### Phase 7: CI/CD・監視
- [ ] CI/CDパイプライン構築
  - [ ] GitHub Actions設定
  - [ ] 自動デプロイ設定
  - [ ] 本番環境設定
- [ ] 監視・分析
  - [ ] Cloudflare Analytics統合
  - [ ] エラー監視設定
  - [ ] パフォーマンス監視

## 📊 進捗チェック

### 完了済み
- [x] プロジェクト設定ファイル作成（claude.json）
- [x] 環境変数設定（claude.env）
- [x] 機密情報管理（claude.secrets）
- [x] タスク管理体制構築

### 現在進行中
- [x] 課題分析・作業計画策定

### 次のアクション
1. [x] Flutter プロジェクトの初期化
2. [x] Cloudflare Workers開発環境セットアップ
3. [x] 基本的な依存関係の追加
4. [x] Makefile作成（開発コマンド自動化）
5. [x] 環境変数設定とシークレット管理
6. [ ] 基本的な認証システム実装

## 🎯 マイルストーン

### Sprint 1（2週間）
- Flutter基本構成完了
- Cloudflare環境セットアップ完了
- 基本認証機能実装完了

### Sprint 2（2週間）
- 道場予約システム実装完了
- 動画アップロード機能実装完了

### Sprint 3（2週間）
- Stripe課金システム統合完了
- E2Eテスト環境構築完了

### Sprint 4（2週間）
- CI/CD環境構築完了
- 本番環境デプロイ完了

## 🔄 レビューセクション

### 変更内容
- [x] Flutter プロジェクトの初期化完了
- [x] Cloudflare Workers API基盤構築完了
- [x] 基本依存関係の追加（HTTP, Bloc, Stripe, Video Player等）
- [x] Makefile による開発コマンド自動化完了
- [x] 環境変数設定とシークレット管理完了
- [x] データベーススキーマ設計完了
- [x] 認証・道場予約・動画・決済のAPIルート実装完了

### 影響範囲
- 開発環境全体の基盤構築完了
- フロントエンドとバックエンドの基本構造確立
- CI/CDの準備完了（Makefile経由）
- 課金システムの基盤完了

### 次回推奨事項
- Flutter UIの実装開始（認証画面から）
- Cloudflare D1データベースの実際の作成・マイグレーション
- Stripe テストキーの設定
- 開発サーバーの起動テスト（make dev, make workers-dev）