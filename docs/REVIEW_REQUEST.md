# JitsuFlow リポジトリ PR レビューご依頼

**宛先:** シニアエンジニア各位
**依頼者:** （ご記入ください）
**依頼日:** 2026-04-29
**回答希望期日:** （ご記入ください）
**目安所要時間:** 通読 60 分 / 詳細レビュー 90〜180 分

---

## 1. サマリー（3 行）

- jitsuflow（BJJ 道場管理プラットフォーム）の **設計レビューで判明した P0 / P1 / P2 の負債を 4 本の PR に分割** して提出済み。
- 自動テスト（lint 0 errors / unit + integration 80 件 pass）と内部 QA レビュー（指摘 17 項目すべて反映済み）は完了。
- **シニア視点での独立レビュー** をいただき、**main マージはレビュアー（依頼者）の手動承認** で実施したい。

---

## 2. 背景

- リポジトリ: <https://github.com/yukihamada/jitsuflow>
- 構成: Cloudflare Workers API（JS）+ Flutter アプリ（Dart）+ ランディング / 管理ダッシュボード
- 直近 2.5 ヶ月稼働停滞期があり、**設計レビューで本番事故になり得る複数の問題** が発覚（パスワードが btoa の Base64 エンコードのみ、Stripe webhook の署名検証なし、自作トークンが無署名、R2 presigned URL がスタブ、等）。
- 上記をテーマ別に **3 本の大 PR + 独立 1 本** に整理して提出。Flutter 側変更は SDK セットアップ後の別 PR (P3) に分離。

---

## 3. 対象 PR（4 本 / すべて Ready for Review）

### 🔵 PR #1 — Stripe webhook 署名検証
<https://github.com/yukihamada/jitsuflow/pull/1>

| 項目 | 内容 |
|---|---|
| Branch | `fix/stripe-webhook-signature` → `main` |
| 規模 | 2 commits / +180 行（うちテスト 100 行）|
| テスト | Unit **10** pass |
| 主目的 | HMAC-SHA256 (Stripe v1 スキーム) 署名検証を導入。設定不備（500）と署名不一致（400）を区別 |
| Stack | 独立（他 PR と無関係） |

### 🔴 PR #2 — P0 セキュリティ強化
<https://github.com/yukihamada/jitsuflow/pull/2>

| 項目 | 内容 |
|---|---|
| Branch | `feat/p0-security-hardening` → `main` |
| 規模 | 6 commits / +800 行（うちテスト 350 行） |
| テスト | Unit + Integration **29** pass |
| 主目的 | (a) Miniflare + D1 統合テスト基盤 / (b) PBKDF2 600k iter + 遅延移行 / (c) ASC `.p8` の `.gitignore` + ローテーション手順 / (d) `wrangler.toml` のプレースホルダー秘密削除 |
| Stack | `main` ベース |

### 🟠 PR #3 — P1 設計負債
<https://github.com/yukihamada/jitsuflow/pull/3>

| 項目 | 内容 |
|---|---|
| Branch | `feat/p1-design-debt` → `feat/p0-security-hardening`（**stack**） |
| 規模 | 6 commits / +800 行 |
| テスト | Unit + Integration **63** pass |
| 主目的 | webhook idempotency（atomic UPDATE）/ admin 認可ガード / JWT 統一（`crypto.subtle.verify`）/ R2 presigned URL（aws4fetch SigV4）|
| Stack | PR #2 の上 — PR #2 マージで GitHub が自動的に base を main に張り替え |

### 🟡 PR #4 — P2 品質改善
<https://github.com/yukihamada/jitsuflow/pull/4>

| 項目 | 内容 |
|---|---|
| Branch | `feat/p2-quality` → `feat/p1-design-debt`（**stack**） |
| 規模 | 7 commits / +500 行 |
| テスト | Unit + Integration **80** pass |
| 主目的 | CORS allowlist（env 駆動）/ KV-backed rate limit / 構造化 JSON ログ / README リポジトリ構成索引 / dead code への DEPRECATED コメント |
| Stack | PR #3 の上 |

### 推奨マージ順

```
#1 (任意のタイミング) → #2 → #3 → #4
```

各 PR 内に複数のコミットがあり、commit-by-commit でも読める粒度に整理してあります（`chore: open ... PR` の空コミットを seed に、機能単位でコミット分割）。

---

## 4. レビュー観点（特にお願いしたい点）

### 🔍 セキュリティ
- [ ] **PBKDF2 実装の暗号学的妥当性**（PR #2: `src/utils/password.js`）。OWASP 2025 600k iter、versioned format、constant-time 比較
- [ ] **JWT 検証フロー**（PR #3: `src/middleware/auth.js`、`src/index.js` requireAuth）。`crypto.subtle.verify` を使った constant-time、exp チェック、`JWT_SECRET` 欠落時の fail closed
- [ ] **Stripe webhook 検証 + idempotency**（PR #1, PR #3: `src/routes/stripe_payments.js`）。署名検証、TOCTOU race の atomic UPDATE 化、subscription 系の冪等性
- [ ] **R2 presigned URL（SigV4）**（PR #3: `src/utils/r2_presigned.js`）。aws4fetch の使い方、expiry 上限、key encoding
- [ ] **管理者認可ガード**（PR #3: `src/index.js` `requireRole`）。401/403 の使い分け、admin 系の網羅性
- [ ] **CORS / レート制限**（PR #4: `src/utils/cors.js`、`src/index.js`）。fail-closed、`X-Forwarded-For` spoof 対策、KV race の現実的な精度

### 🏗 アーキテクチャ・保守性
- [ ] **遅延移行（btoa → PBKDF2）**（PR #2: `src/index.js` login）の race 対策（CAS）と運用上の落とし穴
- [ ] **Miniflare 統合テスト基盤**（PR #2: `tests/integration/_helpers.js`）の妥当性。esbuild bundle キャッシュ、binding 構成、in-memory D1 の隔離
- [ ] **構造化ログの redaction**（PR #4: `src/utils/logger.js`）。JSON.stringify replacer による再帰 scrub の妥当性、未カバーの sensitive 値
- [ ] **dead code（旧 routes/users.js 等）の扱い**。今回 DEPRECATED コメントのみ追加。削除タイミングのご助言

### 🎯 運用・デプロイ
- [ ] **マージ前必須の手動作業**（次節）が PR description に明記されているか
- [ ] **本番環境への影響**（既存 btoa ハッシュユーザーのログイン継続性、Stripe webhook 設定変更のタイミング、R2 secret 設定の段取り）

### 📝 テスト
- [ ] integration tests でカバーされていない攻撃シナリオ・エッジケース
- [ ] Flutter 側の検証が皆無な点（P3 PR で対応予定）が許容範囲か

### ❌ 意図的に「やっていない」もの（妥当性のご判断をお願いします）
- `fastlane/authkey/AuthKey_TYAN6W54AG.p8` を git history から削除（destructive） → revoke を merge precondition として運用で対応
- 旧 dead code（`src/routes/users.js` 等）の物理削除
- DB マイグレーション 45 ファイルの正規化（本番 D1 と擦り合わせ要、別タスク）
- Flutter 側のリファクタ全般（SDK 不在、別 PR）

---

## 5. マージ前にレビュアーに必ず実施いただく手動作業

### PR #1 マージ前
1. 本番 Worker に `STRIPE_WEBHOOK_SECRET` が設定済みか確認
   ```bash
   wrangler secret list --env production | grep STRIPE_WEBHOOK_SECRET
   ```
2. （任意）Stripe CLI で実イベントを 1 度発火し、Worker ログで `webhook.received` を確認
   ```bash
   stripe trigger payment_intent.succeeded
   ```

### PR #2 マージ前 ⚠️ 重要
1. **`AuthKey_TYAN6W54AG.p8` を App Store Connect で revoke**（履歴から消えていないため、これをやらないと PR の趣旨が達成されない）
2. 新キー発行 → ローカル / GitHub Secrets / `Fastfile` 更新（手順は `fastlane/API_KEY_SETUP.md`）
3. 本番 secrets が揃っているか確認
   ```bash
   wrangler secret list --env production
   # 必要: JWT_SECRET, STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET, RESEND_API_KEY, SLACK_WEBHOOK_URL
   ```

### PR #3 マージ前
1. R2 用 secret 4 種を本番に設定
   ```bash
   wrangler secret put R2_ACCOUNT_ID --env production
   wrangler secret put R2_ACCESS_KEY_ID --env production
   wrangler secret put R2_SECRET_ACCESS_KEY --env production
   wrangler secret put R2_BUCKET_NAME --env production
   ```
2. 既存 btoa ハッシュユーザーで login → DB を覗いて `pbkdf2$600000$…` に書き換わっていることをスモーク確認

### PR #4 マージ前
1. CORS allowlist を本番に設定（未設定だと **production はフェイルクローズ** され browsers がブロックされる）
   ```bash
   wrangler secret put CORS_ALLOWED_ORIGINS --env production
   # value: "https://jitsuflow.app,https://www.jitsuflow.app"
   ```

---

## 6. CI ステータスについて補足

GitHub Actions に複数の fail が表示されますが、**すべて本 PR 群と無関係** です：

| チェック | 状態 | 原因 |
|---------|------|------|
| Code Quality / Bundle Size | fail | `pubspec.yaml` 要求の Flutter 3.8.1 vs CI 設定の 3.24.0 mismatch（既存）|
| Dependency Review | fail | repo の Dependency Graph 設定が無効（既存）|
| Unit / API Tests（PR #3, #4） | 不実行 | `ci.yml` の trigger が `branches: [main, develop]` のため、stack PR の base 制約で trigger 条件外 |

→ ローカルで全 4 ブランチの lint + test を順次走行し、すべて green を確認済み。レビュアーがローカルで再走される場合は：

```bash
git checkout feat/p2-quality   # 最も上流のブランチ
npm install
npm run lint
npm run test:unit
npm run test:integration
```

---

## 7. 既知の重要事項

### 🐛 実装中に発見した本番バグ（PR で同時修正済み）
1. `router.all('/api/payments/*', requireAuth → ...)` が webhook を gate → **本番で Stripe からの全 webhook が 401 拒否されていた**（PR #3 で修正）
2. 自作トークン (`btoa(JSON)`) は無署名 → 任意ユーザーが admin token 偽造可能（PR #3 で JWT 統一）
3. R2 presigned URL がスタブ（`?presigned=true` を返すだけ）→ 動画アップロードが本番で全滅（PR #3 で SigV4 実装）

### 📋 並走する作業の事前共有
- App Store Connect API キー（PR #2 関連）の revoke と新キー発行は、PR #2 マージと同期させてください
- 本番 D1 のマイグレーション 45 ファイル正規化は別 PR（schema 正本化）で対応予定。本 PR 群では DB スキーマ変更なし

### 💬 コミット履歴
各 PR は意味単位でコミット分割（`fix(api): ...`, `chore(security): ...`, `feat(observability): ...`, `chore(test): ...`）し、コミットメッセージに「なぜこの変更が必要か」を本文で詳述。commit-by-commit のレビューも可能です。

---

## 8. レビューフォーマット（任意）

レビューコメントは GitHub PR の inline review でいただけると助かります。重要度の目安：

- **Critical**: マージブロッカー（本番事故・データ破壊リスク）
- **High**: マージ前に対応推奨（設計上の整合性）
- **Medium**: 本 PR / フォローアップどちらでも可（要相談）
- **Low / Nit**: フォローアップで対応 OK

---

## 9. 連絡先・補足

- 過去の内部 QA レビュー結果（4 PR 分の指摘 17 件 → 全件対応済）の詳細は各 PR description 末尾「🔧 QA fix follow-up」セクションに記載
- ご質問・ご相談は本 issue / Slack（チャンネル名をご記入ください）でお気軽に
- レビュー観点 §4 のチェックリストは目安です。気になった点はすべて忌憚なくご指摘ください

---

**お忙しい中恐れ入りますが、よろしくお願いいたします。**
