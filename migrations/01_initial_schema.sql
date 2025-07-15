-- JitsuFlow Initial Database Schema (without foreign keys)
-- ブラジリアン柔術トレーニング＆道場予約システム

-- Users table
CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  name TEXT NOT NULL,
  phone TEXT,
  role TEXT DEFAULT 'user',
  stripe_customer_id TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Dojos table
CREATE TABLE IF NOT EXISTS dojos (
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

-- Insert sample dojos
INSERT OR IGNORE INTO dojos (id, name, address, instructor, pricing_info) VALUES
(1, 'YAWARA JIU-JITSU ACADEMY', '東京都渋谷区神宮前1-8-10 The Ice Cubes 8-9F', 'Ryozo Murata (村田良蔵)', 'なでしこプラン¥12,000/月、Yawara-8プラン¥22,000/月、フルタイムプラン¥33,000/月'),
(2, 'Over Limit Sapporo', '北海道札幌市中央区南4条西1丁目15-2 栗林ビル3F', 'Ryozo Murata', 'フルタイム¥12,000/月、マンスリー5¥10,000/月、レディース&キッズ¥8,000/月'),
(3, 'スイープ', '東京都渋谷区千駄ヶ谷3-55-12 ヴィラパルテノン3F', 'スイープインストラクター', '月8回プラン¥22,000/月、通い放題プラン¥33,000/月');