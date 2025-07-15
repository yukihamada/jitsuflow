-- JitsuFlow Database Schema
-- ブラジリアン柔術トレーニング＆道場予約システム

-- Users table
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  name TEXT NOT NULL,
  phone TEXT,
  stripe_customer_id TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Dojos table
CREATE TABLE dojos (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  address TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  website TEXT,
  description TEXT,
  max_capacity INTEGER DEFAULT 20,
  instructor TEXT,
  pricing_info TEXT,
  booking_system TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Class schedules table
CREATE TABLE class_schedules (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  dojo_id INTEGER NOT NULL,
  day_of_week INTEGER NOT NULL, -- 0=Sunday, 1=Monday, etc.
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  class_type TEXT NOT NULL,
  instructor TEXT,
  level TEXT, -- beginner, intermediate, advanced, all-levels
  is_active BOOLEAN DEFAULT TRUE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (dojo_id) REFERENCES dojos(id)
);

-- Bookings table
CREATE TABLE bookings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  dojo_id INTEGER NOT NULL,
  schedule_id INTEGER NOT NULL,
  booking_date DATE NOT NULL,
  status TEXT DEFAULT 'confirmed',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (dojo_id) REFERENCES dojos(id),
  FOREIGN KEY (schedule_id) REFERENCES class_schedules(id)
);

-- Instructors table
CREATE TABLE instructors (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  dojo_id INTEGER NOT NULL,
  belt_rank TEXT NOT NULL, -- black, brown, purple, blue, white
  birth_year INTEGER,
  bio TEXT,
  achievements TEXT, -- JSON array of achievements
  specialties TEXT, -- JSON array of specialties
  profile_image_url TEXT,
  is_head_instructor BOOLEAN DEFAULT FALSE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (dojo_id) REFERENCES dojos(id)
);

-- Videos table
CREATE TABLE videos (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  is_premium BOOLEAN DEFAULT FALSE,
  category TEXT,
  upload_url TEXT,
  file_size INTEGER,
  duration INTEGER,
  thumbnail_url TEXT,
  uploaded_by INTEGER,
  status TEXT DEFAULT 'pending', -- pending, published, unpublished
  views INTEGER DEFAULT 0,
  -- AI Analysis fields
  audio_transcript TEXT,
  detected_techniques TEXT, -- JSON array of detected techniques
  ai_confidence_score REAL,
  ai_generated_title TEXT,
  ai_generated_description TEXT,
  ai_suggested_category TEXT,
  -- Face Recognition fields
  detected_faces TEXT, -- JSON array of detected faces with positions
  face_recognition_data TEXT, -- JSON with face IDs and names
  deepfake_detection_score REAL,
  face_morph_applied BOOLEAN DEFAULT FALSE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (uploaded_by) REFERENCES users(id)
);

-- Teams table
CREATE TABLE teams (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  description TEXT,
  dojo_id INTEGER NOT NULL,
  created_by INTEGER NOT NULL,
  max_members INTEGER DEFAULT 50,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (dojo_id) REFERENCES dojos(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

-- Team memberships table
CREATE TABLE team_memberships (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  team_id INTEGER NOT NULL,
  role TEXT DEFAULT 'member', -- member, leader, admin
  status TEXT DEFAULT 'active', -- active, pending, inactive
  joined_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (team_id) REFERENCES teams(id),
  UNIQUE(user_id, team_id)
);

-- User dojo affiliations
CREATE TABLE user_dojo_affiliations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  dojo_id INTEGER NOT NULL,
  is_primary BOOLEAN DEFAULT FALSE,
  joined_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (dojo_id) REFERENCES dojos(id),
  UNIQUE(user_id, dojo_id)
);

-- Subscriptions table (enhanced)
CREATE TABLE subscriptions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  stripe_subscription_id TEXT UNIQUE NOT NULL,
  plan_type TEXT NOT NULL, -- premium, video_only
  status TEXT NOT NULL, -- active, canceled, past_due
  monthly_price INTEGER NOT NULL, -- in yen
  current_period_start DATETIME,
  current_period_end DATETIME,
  allows_all_dojos BOOLEAN DEFAULT FALSE,
  allows_unlimited_videos BOOLEAN DEFAULT FALSE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Indexes for better performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_bookings_user_id ON bookings(user_id);
CREATE INDEX idx_bookings_dojo_date ON bookings(dojo_id, booking_date);
CREATE INDEX idx_class_schedules_dojo ON class_schedules(dojo_id);
CREATE INDEX idx_class_schedules_day ON class_schedules(day_of_week);
CREATE INDEX idx_class_schedules_instructor ON class_schedules(instructor);
CREATE INDEX idx_videos_category ON videos(category);
CREATE INDEX idx_videos_premium ON videos(is_premium);
CREATE INDEX idx_videos_status ON videos(status);
CREATE INDEX idx_videos_uploaded_by ON videos(uploaded_by);
CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);
CREATE INDEX idx_teams_dojo ON teams(dojo_id);
CREATE INDEX idx_team_memberships_user ON team_memberships(user_id);
CREATE INDEX idx_team_memberships_team ON team_memberships(team_id);
CREATE INDEX idx_user_dojo_affiliations_user ON user_dojo_affiliations(user_id);
CREATE INDEX idx_user_dojo_affiliations_primary ON user_dojo_affiliations(user_id, is_primary);
CREATE INDEX idx_instructors_dojo ON instructors(dojo_id);
CREATE INDEX idx_instructors_belt ON instructors(belt_rank);

-- Insert real dojo data
INSERT INTO dojos (name, address, phone, email, website, description, instructor, pricing_info, booking_system) VALUES
('YAWARA JIU-JITSU ACADEMY', '東京都渋谷区神宮前1-8-10 The Ice Cubes 8-9F', NULL, NULL, 'https://jiujitsu.yawara.fit/', 'プレミアムウェルネス複合施設内の柔術アカデミー。現世界チャンピオンによる指導。', 'Ryozo Murata (村田良蔵)', 'なでしこプラン¥12,000/月、Yawara-8プラン¥22,000/月、フルタイムプラン¥33,000/月', 'リファーラル制'),
('Over Limit Sapporo', '北海道札幌市中央区南4条西1丁目15-2 栗林ビル3F', '011-522-9466', NULL, 'https://overlimit-sapporo.com/', '北海道初のブラジリアン柔術専門アカデミー。世界チャンピオンによる指導で150名以上の会員が在籍。', 'Ryozo Murata', 'フルタイム¥12,000/月、マンスリー5¥10,000/月、レディース&キッズ¥8,000/月', '電話・SNS'),
('スイープ', '東京都渋谷区千駄ヶ谷3-55-12 ヴィラパルテノン3F', NULL, NULL, NULL, '北参道駅徒歩3分の隠れ家的柔術道場。少人数制でアットホームな雰囲気。', 'スイープインストラクター', '月8回プラン¥22,000/月、通い放題プラン¥33,000/月', '直接連絡');

-- Insert sample class schedules for Over Limit Sapporo
INSERT INTO class_schedules (dojo_id, day_of_week, start_time, end_time, class_type, level, instructor) VALUES
(2, 1, '19:00', '20:30', 'ベーシッククラス', 'beginner', 'Ryozo Murata'),
(2, 2, '19:00', '20:30', 'アドバンスクラス', 'advanced', 'Ryozo Murata'),
(2, 3, '19:00', '20:30', 'オープンクラス', 'all-levels', 'Ryozo Murata'),
(2, 4, '19:00', '20:30', 'コンペティションクラス', 'advanced', 'Ryozo Murata'),
(2, 5, '19:00', '20:30', 'ベーシッククラス', 'beginner', 'Ryozo Murata'),
(2, 6, '10:00', '11:30', 'レディースクラス', 'all-levels', NULL),
(2, 6, '14:00', '15:30', 'キッズクラス', 'kids', NULL);

-- Insert sample Sweep schedules
INSERT INTO class_schedules (dojo_id, day_of_week, start_time, end_time, class_type, level, instructor) VALUES
(3, 1, '20:00', '21:30', 'ベーシッククラス', 'beginner', '廣鰭翔大'),
(3, 2, '20:00', '21:30', 'テクニッククラス', 'intermediate', '村田良蔵'),
(3, 4, '20:00', '21:30', 'オープンマット', 'all-levels', '廣鰭翔大'),
(3, 5, '20:00', '21:30', 'スパーリングクラス', 'advanced', '村田良蔵'),
(3, 6, '15:00', '16:30', '週末クラス', 'all-levels', '廣鰭翔大');

-- Insert instructor data
INSERT INTO instructors (name, dojo_id, belt_rank, birth_year, bio, achievements, is_head_instructor) VALUES
-- YAWARA instructors
('村田良蔵', 1, 'black', 1980, 'Yawara柔術アカデミー代表インストラクター。ブラジリアン柔術黒帯（グレイシー直系）でスポーツ柔術日本連盟の会長を務める。北海道出身者として初めてグレイシー一族直系の黒帯を取得。師匠はホイラー・グレイシー系黒帯のクリスチャーノ・カリオカ。', '["2018年SJJIF世界選手権マスター2黒帯フェザー級優勝", "2019年SJJIF世界選手権マスター2黒帯フェザー級優勝", "2013年アブダビワールドプロ日本予選ペナ級優勝"]', TRUE),
('濱田真亮', 1, 'black', 1978, 'Yawara柔術アカデミーインストラクター。2013年（35歳時）に柔術を始めた遅咲きの選手。出身は北海道で、村田良蔵の門下生として実力をつけた。各帯で好成績を収め、初心者にも分かりやすく丁寧な指導を心掛けている。', '["2015年DUMAU JIU-JITSU JAPAN CUPマスター2ライトフェザー級優勝（白帯）", "2019年SJJJF全日本マスター選手権ライトフェザー級優勝（青帯）", "2021年九州国際マスター選手権ライトフェザー級優勝（紫帯）"]', FALSE),

-- Over Limit instructors
('村田良蔵', 2, 'black', 1980, 'OVER LIMIT札幌代表取締役/ヘッドインストラクター。2018年、柔術仲間のエジソン先生との提携により札幌校を立ち上げた。「清潔でアットホームな空間で、本物のグレイシー柔術をファッショナブルに伝えたい」という理念のもと道場を運営。', '["2018年SJJIF世界選手権マスター2黒帯フェザー級優勝", "2019年SJJIF世界選手権マスター2黒帯フェザー級優勝"]', TRUE),
('諸澤陽斗', 2, 'black', 2000, 'インストラクター（黒帯）。2016年から柔術を始め、村田代表の薫陶を受け急成長した新鋭。圧倒的なフットワークとガードワークを武器とする。「柔術は終わりが無いからずっと楽しめる」とその魅力を語る。', '["2018年北海道選手権76kg級＆無差別級優勝", "2019年ASJJF関東選手権70kg級優勝", "2019年SJJIF世界選手権-64kg級準優勝", "2023年JBJJF全日本選手権ライト級優勝"]', FALSE),
('佐藤正幸', 2, 'purple', 1980, 'インストラクター（紫帯）。2018年より柔術を始め、ダイエット目的で取り組む中で2ヶ月で13kg減量に成功。物腰柔らかで面倒見が良く、初心者クラスを中心に「とにかくわかりやすく楽しんでもらう」指導を心掛けている。', '["2023年 第3回 Reversal Cup札幌 ライトフェザー級 優勝"]', FALSE),
('堰本祐希', 2, 'purple', 1999, 'インストラクター（紫帯）。2021年に柔術を開始し、わずか数年で頭角を現した若手有望株。軽量級ながら高い技術と戦略で勝負するスタイル。「体が大きくなくても強くなれる」の体現者として指導。', '["2023年 第3回 Reversal Cup札幌ライトフェザー級＆無差別級優勝", "2024年 SJJIF世界選手権ライトフェザー級3位", "2024年 Copa Alma北海道大会ライトフェザー級優勝"]', FALSE),
('立石修也', 2, 'brown', NULL, 'OVER LIMIT札幌のインストラクター。実力派の茶帯として道場の指導陣を支える。', '[]', FALSE),

-- SWEEP instructors  
('村田良蔵', 3, 'black', 1980, '2025年7月に開設されたSWEEP柔術アカデミーでも指導を担当。「初心者が柔術のダイナミズムを体感し自分の強みを再発見できる場を提供したい」とメッセージを寄せている。', '["2018年SJJIF世界選手権マスター2黒帯フェザー級優勝", "2019年SJJIF世界選手権マスター2黒帯フェザー級優勝"]', FALSE),
('廣鰭翔大', 3, 'brown', 1992, 'SWEEP柔術アカデミーのヘッドインストラクター。スポーツ柔術日本連盟副理事長も務める。2011年に大学で柔術を始め、運動音痴だった自身を変えるべく稽古に励んだ経験を持つ。「初めての方でも安全に楽しく柔術を通じて日常が豊かになる体験を提供したい」と語る。', '["第10回北海道選手権ルースター級＆無差別級優勝（青帯）", "2017年ASJJF DUMAU Korea Grand Prixルースター級優勝", "2022年リカルド・デラヒーバCupマスター1ルースター級優勝"]', TRUE);

-- Insert sample teams
INSERT INTO teams (name, description, dojo_id, created_by) VALUES
('YAWARA競技チーム', 'YAWARA道場の競技志向チーム', 1, 1),
('スイープ初心者の会', 'スイープ道場の初心者向けチーム', 3, 1),
('Over Limit札幌本部', 'Over Limit札幌の本部チーム', 2, 1);

-- Insert sample team memberships
INSERT INTO team_memberships (user_id, team_id, role) VALUES
(1, 1, 'admin'),
(1, 2, 'member'),
(1, 3, 'member');

-- Insert sample user dojo affiliations
INSERT INTO user_dojo_affiliations (user_id, dojo_id, is_primary) VALUES
(1, 1, TRUE),
(1, 2, FALSE),
(1, 3, FALSE);

-- Insert sample subscription plans
INSERT INTO subscriptions (user_id, stripe_subscription_id, plan_type, status, monthly_price, allows_all_dojos, allows_unlimited_videos) VALUES
(1, 'sub_demo_premium', 'premium', 'active', 13000, TRUE, TRUE);

INSERT INTO videos (id, title, description, is_premium, category, status, uploaded_by) VALUES
('video-1', 'ベーシックガード', '基本的なガードのポジションと動きを学ぶ', FALSE, 'basics', 'published', 1),
('video-2', 'アドバンスドスイープ', '上級者向けのスイープテクニック', TRUE, 'advanced', 'published', 1),
('video-3', 'サブミッション集', '効果的なサブミッションの連続技', TRUE, 'submissions', 'published', 1),
('video-4', '試合戦術', '試合での戦術と心理戦', FALSE, 'competition', 'published', 1);