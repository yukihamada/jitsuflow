-- インストラクター複数道場管理・支払い管理拡張
-- JitsuFlow Enhancement: Multi-dojo instructor management and payment system

-- usersテーブルの拡張（roleとstatusカラムが既に存在する場合はスキップ）
ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'user'; -- user, instructor, admin
ALTER TABLE users ADD COLUMN status TEXT DEFAULT 'active'; -- active, inactive, suspended
ALTER TABLE users ADD COLUMN belt_rank TEXT; -- white, blue, purple, brown, black
ALTER TABLE users ADD COLUMN birth_date DATE;
ALTER TABLE users ADD COLUMN primary_dojo_id INTEGER REFERENCES dojos(id);
ALTER TABLE users ADD COLUMN profile_image_url TEXT;
ALTER TABLE users ADD COLUMN joined_at DATETIME;
ALTER TABLE users ADD COLUMN last_login_at DATETIME;

-- インストラクター道場割当テーブル（複数道場兼任対応）
CREATE TABLE instructor_dojo_assignments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  instructor_id INTEGER NOT NULL,
  dojo_id INTEGER NOT NULL,
  -- 料金設定
  usage_fee INTEGER NOT NULL DEFAULT 0, -- 道場使用料（円）
  revenue_share_percentage REAL NOT NULL DEFAULT 50.0, -- 取り分割合（%）
  hourly_rate INTEGER, -- 時給（円）- オプション
  -- 支払い方法
  payment_type TEXT NOT NULL DEFAULT 'revenue_share', -- revenue_share, hourly, fixed
  fixed_monthly_fee INTEGER, -- 固定月額（円）- payment_type='fixed'の場合
  -- ステータス
  status TEXT DEFAULT 'active', -- active, inactive, pending
  start_date DATE NOT NULL,
  end_date DATE,
  -- メタデータ
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (instructor_id) REFERENCES users(id),
  FOREIGN KEY (dojo_id) REFERENCES dojos(id),
  UNIQUE(instructor_id, dojo_id)
);

-- 支払い記録テーブル
CREATE TABLE payments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  -- 支払い情報
  payment_type TEXT NOT NULL, -- instructor_payment, dojo_fee, rental_fee, purchase
  amount INTEGER NOT NULL, -- 金額（円）
  tax_amount INTEGER DEFAULT 0, -- 消費税額
  total_amount INTEGER NOT NULL, -- 合計金額
  -- 関連情報
  instructor_id INTEGER REFERENCES users(id),
  dojo_id INTEGER REFERENCES dojos(id),
  user_id INTEGER REFERENCES users(id), -- 支払い者（物販購入者など）
  -- 支払いステータス
  status TEXT NOT NULL DEFAULT 'pending', -- pending, completed, cancelled, refunded
  payment_method TEXT, -- cash, credit_card, bank_transfer, stripe
  stripe_payment_id TEXT,
  -- 日付
  payment_date DATE NOT NULL,
  due_date DATE,
  paid_at DATETIME,
  -- メタデータ
  description TEXT,
  receipt_url TEXT,
  notes TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- インストラクター給与明細テーブル
CREATE TABLE instructor_payrolls (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  instructor_id INTEGER NOT NULL,
  dojo_id INTEGER NOT NULL,
  -- 期間
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  -- 収益計算
  total_classes INTEGER DEFAULT 0, -- 担当クラス数
  total_hours REAL DEFAULT 0, -- 総勤務時間
  total_students INTEGER DEFAULT 0, -- 総生徒数
  gross_revenue INTEGER DEFAULT 0, -- 総収益
  -- 控除
  usage_fee INTEGER DEFAULT 0, -- 道場使用料
  other_deductions INTEGER DEFAULT 0, -- その他控除
  -- 支払い
  net_payment INTEGER NOT NULL, -- 手取り額
  payment_status TEXT DEFAULT 'pending', -- pending, paid, cancelled
  payment_id INTEGER REFERENCES payments(id),
  -- メタデータ
  calculation_details TEXT, -- JSON形式の詳細計算内訳
  approved_by INTEGER REFERENCES users(id),
  approved_at DATETIME,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (instructor_id) REFERENCES users(id),
  FOREIGN KEY (dojo_id) REFERENCES dojos(id)
);

-- レンタル管理テーブル
CREATE TABLE rentals (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  -- アイテム情報
  item_type TEXT NOT NULL, -- gi, belt, protector, other
  item_name TEXT NOT NULL,
  size TEXT,
  color TEXT,
  condition TEXT DEFAULT 'good', -- new, good, fair, poor
  -- 在庫管理
  dojo_id INTEGER NOT NULL,
  total_quantity INTEGER NOT NULL DEFAULT 1,
  available_quantity INTEGER NOT NULL DEFAULT 1,
  -- 料金
  rental_price INTEGER NOT NULL, -- 1回あたりの料金（円）
  deposit_amount INTEGER DEFAULT 0, -- デポジット額
  -- ステータス
  status TEXT DEFAULT 'available', -- available, maintenance, retired
  -- メタデータ
  barcode TEXT UNIQUE,
  notes TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (dojo_id) REFERENCES dojos(id)
);

-- レンタル履歴テーブル
CREATE TABLE rental_transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  rental_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  -- レンタル情報
  rental_date DATETIME NOT NULL,
  return_due_date DATETIME NOT NULL,
  actual_return_date DATETIME,
  -- 料金
  rental_fee INTEGER NOT NULL,
  deposit_paid INTEGER DEFAULT 0,
  late_fee INTEGER DEFAULT 0,
  damage_fee INTEGER DEFAULT 0,
  total_paid INTEGER NOT NULL,
  -- ステータス
  status TEXT DEFAULT 'active', -- active, returned, overdue, lost
  condition_on_return TEXT, -- good, damaged, lost
  -- 支払い
  payment_id INTEGER REFERENCES payments(id),
  -- メタデータ
  notes TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (rental_id) REFERENCES rentals(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- 物販管理テーブル
CREATE TABLE products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  -- 商品情報
  name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL, -- gi, supplement, equipment, merchandise
  brand TEXT,
  -- 在庫管理
  dojo_id INTEGER NOT NULL,
  sku TEXT UNIQUE,
  current_stock INTEGER DEFAULT 0,
  min_stock_level INTEGER DEFAULT 5,
  -- 価格
  cost_price INTEGER NOT NULL, -- 原価
  selling_price INTEGER NOT NULL, -- 販売価格
  member_price INTEGER, -- 会員価格
  -- ステータス
  status TEXT DEFAULT 'active', -- active, discontinued, out_of_stock
  -- メタデータ
  image_url TEXT,
  barcode TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (dojo_id) REFERENCES dojos(id)
);

-- 売上記録テーブル
CREATE TABLE sales_transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  -- 取引情報
  transaction_type TEXT NOT NULL, -- product_sale, rental, membership, drop_in
  dojo_id INTEGER NOT NULL,
  user_id INTEGER, -- 購入者（非会員の場合NULL）
  staff_id INTEGER NOT NULL, -- 販売担当者
  -- 金額
  subtotal INTEGER NOT NULL,
  tax_amount INTEGER NOT NULL,
  discount_amount INTEGER DEFAULT 0,
  total_amount INTEGER NOT NULL,
  -- 支払い
  payment_method TEXT NOT NULL, -- cash, credit_card, qr_payment
  payment_id INTEGER REFERENCES payments(id),
  -- ステータス
  status TEXT DEFAULT 'completed', -- pending, completed, cancelled, refunded
  -- メタデータ
  items_detail TEXT, -- JSON形式の購入明細
  receipt_number TEXT UNIQUE,
  notes TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (dojo_id) REFERENCES dojos(id),
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (staff_id) REFERENCES users(id)
);

-- スパーリング録画記録テーブル
CREATE TABLE sparring_videos (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  -- 録画情報
  dojo_id INTEGER NOT NULL,
  recorded_by INTEGER NOT NULL, -- 録画者
  recording_date DATETIME NOT NULL,
  -- 参加者
  participant_1_id INTEGER NOT NULL,
  participant_2_id INTEGER NOT NULL,
  -- ビデオ情報
  video_url TEXT,
  thumbnail_url TEXT,
  duration INTEGER, -- 秒数
  file_size INTEGER, -- バイト
  -- メタデータ
  round_number INTEGER,
  weight_class TEXT,
  rule_set TEXT, -- ibjjf, adcc, submission_only
  winner_id INTEGER REFERENCES users(id),
  finish_type TEXT, -- points, submission, draw
  -- プライバシー
  visibility TEXT DEFAULT 'private', -- private, dojo_only, public
  -- ステータス
  status TEXT DEFAULT 'processing', -- processing, available, deleted
  -- 分析データ
  ai_analysis TEXT, -- JSON形式のAI分析結果
  technique_timestamps TEXT, -- JSON形式の技のタイムスタンプ
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (dojo_id) REFERENCES dojos(id),
  FOREIGN KEY (recorded_by) REFERENCES users(id),
  FOREIGN KEY (participant_1_id) REFERENCES users(id),
  FOREIGN KEY (participant_2_id) REFERENCES users(id)
);

-- 道場モード設定テーブル
CREATE TABLE dojo_mode_settings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  dojo_id INTEGER NOT NULL UNIQUE,
  -- モード設定
  pos_enabled BOOLEAN DEFAULT TRUE, -- POS機能有効化
  rental_enabled BOOLEAN DEFAULT TRUE, -- レンタル機能有効化
  sparring_recording_enabled BOOLEAN DEFAULT TRUE, -- スパーリング録画有効化
  -- デフォルト設定
  default_tax_rate REAL DEFAULT 10.0, -- 消費税率（%）
  default_member_discount REAL DEFAULT 10.0, -- 会員割引率（%）
  -- 自動化設定
  auto_send_receipts BOOLEAN DEFAULT TRUE,
  auto_backup_videos BOOLEAN DEFAULT TRUE,
  -- UI設定
  theme_color TEXT DEFAULT '#1B5E20',
  logo_url TEXT,
  -- メタデータ
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (dojo_id) REFERENCES dojos(id)
);

-- 経営分析用のビュー作成
CREATE VIEW revenue_summary AS
SELECT 
  d.id as dojo_id,
  d.name as dojo_name,
  DATE('now', 'start of month') as period,
  -- 収益
  COALESCE(SUM(CASE WHEN st.transaction_type = 'membership' THEN st.total_amount ELSE 0 END), 0) as membership_revenue,
  COALESCE(SUM(CASE WHEN st.transaction_type = 'product_sale' THEN st.total_amount ELSE 0 END), 0) as product_revenue,
  COALESCE(SUM(CASE WHEN st.transaction_type = 'rental' THEN st.total_amount ELSE 0 END), 0) as rental_revenue,
  COALESCE(SUM(st.total_amount), 0) as total_revenue,
  -- コスト
  COALESCE(SUM(CASE WHEN p.payment_type = 'instructor_payment' THEN p.total_amount ELSE 0 END), 0) as instructor_costs,
  -- 利益
  COALESCE(SUM(st.total_amount), 0) - COALESCE(SUM(CASE WHEN p.payment_type = 'instructor_payment' THEN p.total_amount ELSE 0 END), 0) as gross_profit
FROM dojos d
LEFT JOIN sales_transactions st ON d.id = st.dojo_id 
  AND st.created_at >= DATE('now', 'start of month')
  AND st.status = 'completed'
LEFT JOIN payments p ON d.id = p.dojo_id 
  AND p.payment_date >= DATE('now', 'start of month')
  AND p.status = 'completed'
GROUP BY d.id, d.name;

-- インデックス追加
CREATE INDEX idx_instructor_assignments_instructor ON instructor_dojo_assignments(instructor_id);
CREATE INDEX idx_instructor_assignments_dojo ON instructor_dojo_assignments(dojo_id);
CREATE INDEX idx_payments_type_status ON payments(payment_type, status);
CREATE INDEX idx_payments_date ON payments(payment_date);
CREATE INDEX idx_payrolls_instructor ON instructor_payrolls(instructor_id);
CREATE INDEX idx_payrolls_period ON instructor_payrolls(period_start, period_end);
CREATE INDEX idx_rentals_dojo ON rentals(dojo_id);
CREATE INDEX idx_rental_transactions_status ON rental_transactions(status);
CREATE INDEX idx_products_dojo ON products(dojo_id);
CREATE INDEX idx_sales_transactions_dojo_date ON sales_transactions(dojo_id, created_at);
CREATE INDEX idx_sparring_videos_dojo ON sparring_videos(dojo_id);
CREATE INDEX idx_sparring_videos_participants ON sparring_videos(participant_1_id, participant_2_id);