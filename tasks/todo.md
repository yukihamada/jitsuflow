# Subscription Management - JitsuFlow

## 概要
JitsuFlow (Flutter iOS) と jiuflow-ssr (Rust backend) 間でサブスクリプション管理を実装する。
Stripe (Web経由) と Apple In-App Purchase (iOS) の2系統を統合し、ユーザーのサブスク状態を一元管理する。

## 調査結果

### 現状のインフラ
- **jiuflow-ssr**: Rust/axum, SQLite, Fly.io (jiuflow-ssr.fly.dev)
- **jitsuflow**: Flutter 3.8+, flutter_bloc, go_router, dio, flutter_secure_storage
- **Stripe**: STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET 設定済み (Fly.io secrets)
- **既存DB**: `subscriptions` テーブルあり (user_id, stripe_customer_id, stripe_subscription_id, stripe_price_id, plan, status, current_period_end, cancel_at_period_end)
- **既存Webhook**: checkout.session.completed, customer.subscription.updated, customer.subscription.deleted 処理済み
- **Plans**: Founder ¥980, Regular ¥1,480, old Regular ¥1,900, Pro ¥2,900 (約85 active, 15 canceled, 25 trialing, 2 past_due)

### 既存コード (利用可能)
- `jiuflow-ssr/src/handlers/stripe.rs`: checkout session作成 + webhook処理
- `jiuflow-ssr/src/handlers/api.rs`: api_v1_* パターン (JSON API, OptionalUser auth)
- `jitsuflow/lib/core/api/api_client.dart`: dio ベース, baseUrl=jiuflow-ssr.fly.dev, Bearer token auth
- `jitsuflow/lib/features/auth/`: magic link auth, FeatureAuthBloc, UserModel (id, email, name, role)
- `jitsuflow/lib/screens/subscription/subscription_screen.dart`: 旧SubscriptionScreen (ApiService経由, 別baseUrl)
- `jitsuflow/lib/features/mypage/screens/mypage_screen.dart`: 現行マイページ

### 2つのAPIクライアントが共存
1. `lib/core/api/api_client.dart` → baseUrl: jiuflow-ssr.fly.dev (新: features/ 以下で使用)
2. `lib/services/api_service.dart` → baseUrl: api.jitsuflow.app (旧: screens/ 以下で使用)
- **方針**: 新機能は `ApiClient` (jiuflow-ssr.fly.dev) を使う

### Apple IAP 要件
- iOS アプリ内でデジタルコンテンツの課金は StoreKit 必須 (Apple 規約)
- `in_app_purchase` Flutter パッケージを使用
- サーバーサイドで Apple receipt verification が必要
- App Store Connect で商品登録が前提

### 注意点
- `flutter_stripe` は pubspec.yaml にあるが、iOS IAP では使えない (Apple 規約)
- flutter_stripe は Web checkout redirect や物理商品決済には使える
- 現行 `SubscriptionScreen` は旧 ApiService (api.jitsuflow.app) を参照 → 新 ApiClient に移行必要

---

## 実装ステップ

### Phase 1: サーバー API (jiuflow-ssr) — 推定: 中

- [ ] **Step 1.1**: `GET /api/v1/subscription` — ユーザーのサブスク状態を返す
  - 認証: Bearer token (OptionalUser → 401 if missing)
  - email からユーザー特定 → subscriptions テーブル参照
  - レスポンス: `{ plan, status, current_period_end, cancel_at_period_end, provider }`
  - Stripe API でリアルタイム確認 or DB キャッシュ (DB優先、webhook で更新済み)

- [ ] **Step 1.2**: `POST /api/v1/subscription/checkout` — Stripe checkout session 作成 (JSON API版)
  - 入力: `{ price_id, success_url?, cancel_url? }`
  - 認証必須、customer_email を自動セット
  - 既存 `stripe.rs::checkout` の JSON API 版 (Form → JSON, redirect → session URL 返却)
  - レスポンス: `{ session_url }`

- [ ] **Step 1.3**: `POST /api/v1/subscription/verify-apple` — Apple receipt 検証
  - 入力: `{ receipt_data, product_id }`
  - Apple の verifyReceipt エンドポイント (sandbox / production) にサーバーサイドで検証
  - 成功時: subscriptions テーブルに `provider='apple'` で upsert
  - レスポンス: `{ ok, plan, status, expires_at }`

- [ ] **Step 1.4**: `POST /api/v1/subscription/cancel` — サブスクキャンセル API
  - Stripe: cancel_at_period_end = true に設定 (即解約ではない)
  - Apple: サーバーからはキャンセル不可 → クライアントに「設定 > サブスクリプション」案内

- [ ] **Step 1.5**: DB スキーマ拡張
  - subscriptions テーブルに `provider TEXT DEFAULT 'stripe'` カラム追加
  - subscriptions テーブルに `apple_original_transaction_id TEXT` カラム追加
  - マイグレーション: ALTER TABLE (jiuflow-ssr の init_db 内に追加)

- [ ] **Step 1.6**: ルーティング登録 (main.rs)
  - `/api/v1/subscription` → GET
  - `/api/v1/subscription/checkout` → POST
  - `/api/v1/subscription/verify-apple` → POST
  - `/api/v1/subscription/cancel` → POST

### Phase 2: Flutter サブスクサービス層 — 推定: 中

- [ ] **Step 2.1**: `lib/features/subscription/models/subscription_model.dart` 作成
  - fields: plan, status, provider, currentPeriodEnd, cancelAtPeriodEnd

- [ ] **Step 2.2**: `lib/features/subscription/services/subscription_service.dart` 作成
  - `fetchStatus()` → GET /api/v1/subscription
  - `createCheckout(priceId)` → POST /api/v1/subscription/checkout → url_launcher で開く
  - `verifyAppleReceipt(receiptData, productId)` → POST /api/v1/subscription/verify-apple
  - `cancel()` → POST /api/v1/subscription/cancel
  - ApiClient (dio) を使用

- [ ] **Step 2.3**: `lib/features/subscription/bloc/subscription_bloc.dart` 作成
  - Events: CheckSubscription, Subscribe, CancelSubscription, RestoreApplePurchase
  - States: SubscriptionInitial, SubscriptionLoading, SubscriptionLoaded(model), SubscriptionError

- [ ] **Step 2.4**: UserModel 拡張
  - `subscription` フィールド追加 (nullable SubscriptionModel)
  - ログイン成功後に自動取得

### Phase 3: Flutter Paywall / Upgrade UI — 推定: 中

- [ ] **Step 3.1**: `lib/features/subscription/screens/paywall_screen.dart` 作成
  - ダーク UI (既存デザイン: Color(0xFF09090B) ベース)
  - プラン一覧カード: Founder ¥980, Regular ¥1,480, Pro ¥2,900
  - iOS: 「Apple で購入」ボタン (in_app_purchase)
  - Web/非iOS: 「Stripe で購入」ボタン (url_launcher で checkout URL を開く)
  - 「リストア」ボタン (Apple IAP の restore)

- [ ] **Step 3.2**: `lib/features/subscription/screens/subscription_status_screen.dart` 作成
  - 現在のプラン表示、期限表示
  - キャンセルボタン
  - MyPage の「サブスクリプション」メニューから遷移

- [ ] **Step 3.3**: MyPage にサブスク状態表示を統合
  - `mypage_screen.dart` にプランバッジ追加 (プロフィール横)
  - メニューに「サブスクリプション管理」追加
  - go_router にルート追加: `/subscription`, `/paywall`

- [ ] **Step 3.4**: ログイン後の自動チェック
  - FeatureAuthBloc の `_onVerifyTokenRequested` 成功後にサブスク確認
  - 未課金 or expired → PaywallScreen へ遷移 (or バナー表示)

### Phase 4: iOS In-App Purchase — 推定: 大

- [ ] **Step 4.1**: `in_app_purchase` パッケージ追加
  - pubspec.yaml に `in_app_purchase: ^3.1.0` 追加
  - flutter_stripe は残す (Web checkout redirect 用途)

- [ ] **Step 4.2**: App Store Connect で商品登録
  - Auto-Renewable Subscription: `com.jitsuflow.founder` (¥980/月)
  - Auto-Renewable Subscription: `com.jitsuflow.regular` (¥1,480/月)
  - Auto-Renewable Subscription: `com.jitsuflow.pro` (¥2,900/月)
  - Subscription Group: "JitsuFlow Premium"

- [ ] **Step 4.3**: `lib/features/subscription/services/apple_iap_service.dart` 作成
  - InAppPurchase.instance の初期化
  - purchaseStream のリスン
  - 購入フロー: buyNonConsumable → receipt取得 → サーバー検証
  - リストア: restorePurchases
  - Platform check: `Platform.isIOS` でのみ有効

- [ ] **Step 4.4**: Paywall に IAP 統合
  - iOS 判定 → Apple IAP ボタン表示
  - 購入成功 → verify-apple API → SubscriptionBloc 更新
  - エラーハンドリング: ユーザーキャンセル、決済失敗、ネットワークエラー

- [ ] **Step 4.5**: Apple Server-to-Server Notification (将来対応)
  - App Store Server Notifications V2 のエンドポイント
  - `POST /api/v1/subscription/apple-webhook`
  - renewal, cancellation, refund イベント処理

### Phase 5: テスト & デプロイ — 推定: 中

- [ ] **Step 5.1**: サーバー側テスト
  - `/api/v1/subscription` が正しいJSON返すか curl で確認
  - Stripe test mode で checkout session 作成 → webhook 受信
  - Apple sandbox receipt での verify-apple テスト

- [ ] **Step 5.2**: Flutter 側テスト
  - SubscriptionBloc のユニットテスト
  - PaywallScreen の Widget テスト
  - iOS Simulator で IAP sandbox テスト

- [ ] **Step 5.3**: jiuflow-ssr デプロイ
  - `fly deploy -a jiuflow-ssr --remote-only`
  - 動作確認: `curl https://jiuflow-ssr.fly.dev/api/v1/subscription -H "Authorization: Bearer <token>"`

- [ ] **Step 5.4**: jitsuflow TestFlight アップロード
  - ビルド番号インクリメント (現在: +11 → +12)
  - `flutter build ipa --release`
  - TestFlight へアップロード

---

## テスト方針
- [ ] サーバー: curl で各 API エンドポイントの正常系/異常系テスト
- [ ] サーバー: Stripe webhook のシグネチャ検証テスト (test mode)
- [ ] Flutter: SubscriptionBloc のユニットテスト (mock API)
- [ ] Flutter: iOS Simulator で IAP sandbox テスト
- [ ] E2E: magic link ログイン → サブスク確認 → paywall 表示 → 購入 → ステータス更新

## リスク
- **Apple 審査**: IAP 実装が不完全だとリジェクトされる。StoreKit 2 対応が推奨されつつある
- **Stripe/Apple 二重課金**: 同じユーザーが両方から購入する可能性。provider フィールドで追跡し、UI で片方のみ表示
- **Apple receipt 検証の非推奨化**: verifyReceipt API は deprecated。App Store Server API (V2) への移行を将来計画
- **既存ユーザー移行**: 85 active subscribers は全て Stripe 経由。新規 iOS ユーザーのみ IAP 対象
- **Apple 手数料**: Apple は 30% (Small Business Program なら 15%) vs Stripe 3.6%。Web 誘導の方が利益率高い

## 完了条件
1. `GET /api/v1/subscription` がログインユーザーの正しいプラン/ステータスを返す
2. `POST /api/v1/subscription/checkout` が Stripe checkout URL を返し、決済完了で DB 更新される
3. Flutter アプリでログイン後にサブスク状態が表示される
4. 未課金ユーザーに paywall が表示され、購入フローに進める
5. iOS で in_app_purchase による購入が完了し、サーバーで receipt 検証 → DB 更新される
6. MyPage にサブスク状態とプランバッジが表示される

## 推奨実装順序
**Phase 1 → Phase 2 → Phase 3 → Phase 5 (Stripe のみ) → Phase 4 → Phase 5 (Apple IAP)**

理由: Stripe 連携は既存コード (webhook, checkout) が大部分揃っているため先に完成させ、Apple IAP は後から追加する方がリスク管理しやすい。
