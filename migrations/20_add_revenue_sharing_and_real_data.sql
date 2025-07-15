-- Disable foreign key constraints temporarily
PRAGMA foreign_keys = OFF;

-- Create dojo revenue sharing settings table
CREATE TABLE IF NOT EXISTS dojo_revenue_settings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    dojo_id INTEGER NOT NULL,
    default_instructor_rate INTEGER DEFAULT 70, -- デフォルトインストラクター取り分（%）
    default_dojo_rate INTEGER DEFAULT 30, -- デフォルト道場取り分（%）
    default_usage_fee INTEGER DEFAULT 0, -- デフォルト使用料（固定額）
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (dojo_id) REFERENCES dojos(id),
    UNIQUE(dojo_id)
);

-- Create instructor custom revenue settings table
CREATE TABLE IF NOT EXISTS instructor_revenue_settings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    instructor_id INTEGER NOT NULL,
    dojo_id INTEGER NOT NULL,
    custom_instructor_rate INTEGER, -- カスタムインストラクター取り分（%）
    custom_dojo_rate INTEGER, -- カスタム道場取り分（%）
    custom_usage_fee INTEGER, -- カスタム使用料（固定額）
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (instructor_id) REFERENCES instructors(id),
    FOREIGN KEY (dojo_id) REFERENCES dojos(id),
    UNIQUE(instructor_id, dojo_id)
);

-- Insert default revenue settings for each dojo
INSERT INTO dojo_revenue_settings (dojo_id, default_instructor_rate, default_dojo_rate, default_usage_fee) VALUES
(1, 70, 30, 3000), -- YAWARA東京: インストラクター70%, 道場30%, 使用料3000円
(2, 65, 35, 2500), -- SWEEP東京: インストラクター65%, 道場35%, 使用料2500円
(3, 75, 25, 2000); -- OverLimit札幌: インストラクター75%, 道場25%, 使用料2000円

-- Clear existing instructors
DELETE FROM instructor_dojos;
DELETE FROM instructors;

-- Insert real instructors from YAWARA
INSERT INTO instructors (id, name, email, phone, belt_rank, years_experience, bio, is_active) VALUES
(1, '一木', 'ichiki@yawara-bjj.com', NULL, '黒帯4段', 20, 'YAWARAのトップインストラクター。パーソナルトレーニングとリラックスヒーリングを担当。', 1),
(2, '首藤', 'shuto@yawara-bjj.com', NULL, '黒帯3段', 15, 'パーソナルトレーニングとリラックスヒーリングの専門家。', 1),
(3, '小川', 'ogawa@yawara-bjj.com', NULL, '黒帯2段', 12, 'パーソナルトレーニング専門インストラクター。', 1),
(4, '古川', 'furukawa@yawara-bjj.com', NULL, '黒帯2段', 10, 'パーソナルトレーニング専門インストラクター。', 1),
(5, 'シルバ', 'silva@yawara-bjj.com', NULL, '黒帯3段', 18, 'ブラジル出身。パーソナルトレーニング専門。', 1),
(6, '田邊', 'tanabe@yawara-bjj.com', NULL, '黒帯1段', 8, 'パーソナルトレーニング専門インストラクター。', 1),
(7, '村田', 'murata@yawara-bjj.com', NULL, '黒帯5段', 25, '柔術パーソナルトレーニングのスペシャリスト。', 1),
(8, '濱田', 'hamada@yawara-bjj.com', NULL, '黒帯3段', 15, '柔術パーソナルトレーニング専門。', 1),
(9, '廣鰭', 'hirohata@yawara-bjj.com', NULL, '黒帯2段', 12, '柔術パーソナルトレーニング専門。', 1),
(10, '中山', 'nakayama@yawara-bjj.com', NULL, '茶帯', 6, '柔術パーソナルトレーニング担当。', 1),
(11, '立石', 'tateishi@yawara-bjj.com', NULL, '紫帯', 5, '柔術スタートプラン専門インストラクター。', 1),
(12, '李', 'lee@yawara-bjj.com', NULL, '特別認定', 15, 'リラックスヒーリング専門セラピスト。', 1),
(13, '樋田', 'hida@yawara-bjj.com', NULL, '特別認定', 10, 'リラックスヒーリング専門セラピスト。', 1);

-- Assign instructors to YAWARA Tokyo (all instructors are at YAWARA)
INSERT INTO instructor_dojos (instructor_id, dojo_id, role, start_date, is_active) VALUES
(1, 1, 'head_instructor', '2015-01-01', 1),
(2, 1, 'instructor', '2018-04-01', 1),
(3, 1, 'instructor', '2019-06-01', 1),
(4, 1, 'instructor', '2020-03-01', 1),
(5, 1, 'instructor', '2016-09-01', 1),
(6, 1, 'instructor', '2021-01-01', 1),
(7, 1, 'head_instructor', '2010-05-01', 1),
(8, 1, 'instructor', '2018-07-01', 1),
(9, 1, 'instructor', '2019-11-01', 1),
(10, 1, 'instructor', '2022-02-01', 1),
(11, 1, 'instructor', '2022-06-01', 1),
(12, 1, 'instructor', '2018-01-01', 1),
(13, 1, 'instructor', '2020-08-01', 1);

-- Add custom revenue settings for premium instructors
INSERT INTO instructor_revenue_settings (instructor_id, dojo_id, custom_instructor_rate, custom_dojo_rate, custom_usage_fee, notes) VALUES
(1, 1, 80, 20, 2000, '一木トレーナー特別レート'),
(7, 1, 85, 15, 1500, '村田トレーナー特別レート');

-- Clear existing products
DELETE FROM products;

-- Insert YAWARA products
INSERT INTO products (name, description, price, category, image_url, stock_quantity, is_active) VALUES
-- パーソナルトレーニング
('【新規】パーソナルトレーニング セッション(一木)', '【新規のお客様対象】一木トレーナーが担当するパーソナルトレーニング（55分×12回）のセッションです。※チケット有効期間はスタート日より150日間です。', 330000, 'training', NULL, 999, 1),
('【継続】パーソナルトレーニング セッション(一木)', '【継続のお客様対象】一木トレーナーが担当するパーソナルトレーニング（55分×12回）のセッションです。※チケット有効期間はスタート日より150日間です。', 320000, 'training', NULL, 999, 1),
('【新規】パーソナルトレーニング セッション(首藤)', '【新規のお客様対象】首藤トレーナーが担当するパーソナルトレーニング（55分×12回）のセッションです。※チケット有効期間はスタート日より150日間です。', 268500, 'training', NULL, 999, 1),
('【継続】パーソナルトレーニング セッション(首藤)', '【継続のお客様対象】首藤トレーナーが担当するパーソナルトレーニング（55分×12回）のセッションです。※チケット有効期間はスタート日より150日間です。', 258500, 'training', NULL, 999, 1),
('【新規】パーソナルトレーニング セッション(小川)', '【新規のお客様対象】小川トレーナーが担当するパーソナルトレーニング（55分×12回）のセッションです。※チケット有効期間はスタート日より150日間です。', 268500, 'training', NULL, 999, 1),
('【継続】パーソナルトレーニング セッション(小川)', '【継続のお客様対象】小川トレーナーが担当するパーソナルトレーニング（55分×12回）のセッションです。※チケット有効期間はスタート日より150日間です。', 258500, 'training', NULL, 999, 1),
('【新規】パーソナルトレーニング セッション(古川)', '【新規のお客様対象】古川トレーナーが担当するパーソナルトレーニング（55分×12回）のセッションです。※チケット有効期間はスタート日より150日間です。', 268500, 'training', NULL, 999, 1),
('【継続】パーソナルトレーニング セッション(古川)', '【継続のお客様対象】古川トレーナーが担当するパーソナルトレーニング（55分×12回）のセッションです。※チケット有効期間はスタート日より150日間です。', 258500, 'training', NULL, 999, 1),
('【新規】パーソナルトレーニング セッション(シルバ)', '【新規のお客様対象】シルバトレーナーが担当するパーソナルトレーニング（55分×12回）のセッションです。※チケット有効期間はスタート日より150日間です。', 268500, 'training', NULL, 999, 1),
('【継続】パーソナルトレーニング セッション(シルバ)', '【継続のお客様対象】シルバトレーナーが担当するパーソナルトレーニング（55分×12回）のセッションです。※チケット有効期間はスタート日より150日間です。', 258500, 'training', NULL, 999, 1),
('【新規】パーソナルトレーニング セッション(田邊)', '【新規のお客様対象】田邊トレーナーが担当するパーソナルトレーニング（55分×12回）のセッションです。※チケット有効期間はスタート日より150日間です。', 268500, 'training', NULL, 999, 1),
('【継続】パーソナルトレーニング セッション(田邊)', '【継続のお客様対象】田邊トレーナーが担当するパーソナルトレーニング（55分×12回）のセッションです。※チケット有効期間はスタート日より150日間です。', 258500, 'training', NULL, 999, 1),
('パーソナルトレーニング体験セッション(90分)', 'パーソナルトレーニングの体験セッション（90分間）です。※お客様に合わせた最適なトレーナーをアサインいたします。', 16500, 'training', NULL, 999, 1),

-- リラックスヒーリング
('リラックスヒーリング セッション（李 / 85分）', '李が担当するリラックスヒーリングのスポットセッション（85分）です。※日程要相談', 165000, 'healing', NULL, 999, 1),
('リラックスヒーリング セッション（樋田 / 85分）', '樋田が担当するリラックスヒーリングのスポットセッション（85分）です。※チケット有効期限はご購入日から60日間です。', 30000, 'healing', NULL, 999, 1),
('リラックスヒーリング セッション（樋田 / 55分 x 2回）', '樋田が担当するリラックスヒーリングのスポットセッション（55分） x 2回チケットです。※チケット有効期限はご購入日から120日間です。', 55000, 'healing', NULL, 999, 1),
('リラックスヒーリング セッション（一木）', '一木が担当するリラックスヒーリングのスポットセッション（55分）です。※チケット有効期限はご購入日から60日間です。', 22000, 'healing', NULL, 999, 1),
('リラックスヒーリングセッション(一木 / 55分 x 10回）', '一木が担当するリラックスヒーリングのスポットセッション（55分） x 10回チケットです。※チケット有効期限はご購入日から180日間です。', 198000, 'healing', NULL, 999, 1),
('リラックスヒーリング セッション（首藤）', '首藤が担当するリラックスヒーリングのスポットセッション（55分）です。※チケット有効期限はご購入日から60日間です。', 22000, 'healing', NULL, 999, 1),
('リラックスヒーリングセッション(首藤 / 55分 x 10回）', '首藤が担当するリラックスヒーリングのスポットセッション（55分） x 10回チケットです。※チケット有効期限はご購入日から180日間です。', 198000, 'healing', NULL, 999, 1),
('カイロプラクティック セッション(スポット)', '【チケット購入済のお客様対象】カイロプラクティックのスポットセッション（55分）です。※チケット有効期間は購入日より60日間です。', 16500, 'healing', NULL, 999, 1),

-- 柔術パーソナル
('柔術パーソナルトレーニング Personal 3(村田)', '【柔術パーソナル初回限定】村田トレーナーが担当する柔術パーソナルトレーニング（60分×3回）のセッションです。', 99000, 'bjj_training', NULL, 999, 1),
('柔術パーソナルトレーニング Personal 10(村田)', '【申込み済のお客様対象】村田トレーナーが担当する柔術パーソナルトレーニング（60分×10回）のセッションです。', 330000, 'bjj_training', NULL, 999, 1),
('柔術パーソナルトレーニング Personal 3(濱田)', '【柔術パーソナル初回限定】濱田トレーナーが担当する柔術パーソナルトレーニング（60分×3回）のセッションです。', 49500, 'bjj_training', NULL, 999, 1),
('柔術パーソナルトレーニング Personal 10(濱田)', '【申込み済のお客様対象】濱田トレーナーが担当する柔術パーソナルトレーニング（60分×10回）のセッションです。', 165000, 'bjj_training', NULL, 999, 1),
('柔術パーソナルトレーニング Personal 3(廣鰭)', '【柔術パーソナル初回限定】廣鰭トレーナーが担当する柔術パーソナルトレーニング（60分×3回）のセッションです。', 49500, 'bjj_training', NULL, 999, 1),
('柔術パーソナルトレーニング Personal 10(廣鰭)', '【申込み済のお客様対象】廣鰭トレーナーが担当する柔術パーソナルトレーニング（60分×10回）のセッションです。', 165000, 'bjj_training', NULL, 999, 1),
('柔術パーソナルトレーニング Personal 3(中山)', '【柔術パーソナル初回限定】中山トレーナーが担当する柔術パーソナルトレーニング（60分×3回）のセッションです。', 33000, 'bjj_training', NULL, 999, 1),
('柔術パーソナルトレーニング Personal 10(中山)', '【申込み済のお客様対象】中山トレーナーが担当する柔術パーソナルトレーニング（60分×10回）のセッションです。', 110000, 'bjj_training', NULL, 999, 1),
('柔術パーソナルトレーニング Personal 10(立石)', '【申込み済のお客様対象】立石トレーナーが担当する柔術パーソナルトレーニング（60分×10回）のセッションです。', 110000, 'bjj_training', NULL, 999, 1),
('柔術スタートプラン（立石）', '【柔術スタートプラン】立石トレーナーが担当する、くるくるなどのベーシックムーブメントを学ぶセッションです（55分×3回）。', 23100, 'bjj_training', NULL, 999, 1),

-- 道着・装備
('スターターキット', '柔術をスタートするために最初に必要な、YAWARA道着・ラッシュガード・帯のセットです。', 33000, 'equipment', NULL, 50, 1),
('【柔術体験者専用】道着レンタル', '柔術体験レッスン参加者専用の道着レンタルです。', 2200, 'rental', NULL, 999, 1),
('柔術道着レンタル', '柔術のレッスンで使用する道着、帯のレンタルです。', 3300, 'rental', NULL, 999, 1),
('柔術道着レンタル（上）', '柔術のレッスンで使用する道着上のレンタルです。', 2200, 'rental', NULL, 999, 1),
('柔術道着レンタル（下）', '柔術のレッスンで使用する道着下のレンタルです。', 1100, 'rental', NULL, 999, 1),
('ラッシュガードレンタル', '柔術のレッスンで使用するラッシュガードのレンタルです。', 1100, 'rental', NULL, 999, 1),
('帯レンタル', '柔術のレッスンで使用する帯のレンタルです。', 550, 'rental', NULL, 999, 1),
('バスタオルレンタル', 'シャワーご利用の際にお使いいただく、レンタルのバスタオルです。', 275, 'rental', NULL, 999, 1),

-- その他
('水（Water）', 'ミネラルウォーター', 108, 'other', NULL, 999, 1),
('yawara柔術体験会', '無料体験会チケット', 0, 'other', NULL, 999, 1),
('柔術プラン差額チケット（SWEEPダブル会員）', 'SWEEPダブル会員用の差額チケット', 11000, 'other', NULL, 999, 1),
('YJAインストラクター養成講座（Purple Belt course）', 'YAWARAインストラクター養成講座（紫帯コース）', 440000, 'training', NULL, 10, 1);

-- Re-enable foreign key constraints
PRAGMA foreign_keys = ON;