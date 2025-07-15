-- Drop the old instructors table
DROP TABLE IF EXISTS instructors;
DROP TABLE IF EXISTS instructor_dojos;

-- Create new instructors table without dojo_id (many-to-many relationship)
CREATE TABLE instructors (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT UNIQUE,
    phone TEXT,
    belt_rank TEXT NOT NULL,
    years_experience INTEGER,
    bio TEXT,
    profile_image_url TEXT,
    is_active INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Create instructor-dojo relationship table
CREATE TABLE instructor_dojos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    instructor_id INTEGER NOT NULL,
    dojo_id INTEGER NOT NULL,
    role TEXT DEFAULT 'instructor',
    start_date DATE,
    end_date DATE,
    is_active INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (instructor_id) REFERENCES instructors(id),
    FOREIGN KEY (dojo_id) REFERENCES dojos(id),
    UNIQUE(instructor_id, dojo_id)
);

-- Delete existing dojos
DELETE FROM dojos;

-- Insert only 3 dojos with real domains
INSERT INTO dojos (id, name, address, phone, email, website, description, max_capacity, created_at, updated_at) VALUES
(1, 'YAWARA東京', '東京都渋谷区道玄坂1-15-3', '03-1234-5678', 'tokyo@yawara-bjj.com', 'https://yawara-bjj.com/tokyo', 'YAWARAブランドの東京本店。初心者から上級者まで幅広く対応。最新設備を完備し、プロフェッショナルな指導を提供。', 40, datetime('now'), datetime('now')),
(2, 'SWEEP東京', '東京都港区赤坂3-21-10', '03-2345-6789', 'tokyo@sweep-bjj.com', 'https://sweep-bjj.com/tokyo', 'SWEEP愛好者が集まる専門道場。テクニカルな技術指導に定評があり、競技者育成にも力を入れています。', 35, datetime('now'), datetime('now')),
(3, 'OverLimit札幌', '北海道札幌市中央区南3条西5丁目1-1', '011-123-4567', 'sapporo@overlimit-bjj.com', 'https://overlimit-bjj.com/sapporo', '限界を超える、をモットーに北海道最大級の柔術道場。冬季も快適な室内環境で激しいトレーニングを提供。', 50, datetime('now'), datetime('now'));

-- Insert instructors
INSERT INTO instructors (id, name, email, phone, belt_rank, years_experience, bio, is_active) VALUES
(1, '山田太郎', 'yamada@jitsuflow.app', '090-1111-2222', '黒帯3段', 15, '柔術歴15年。ブラジルでの修行経験あり。テクニカルな指導に定評。', 1),
(2, '鈴木一郎', 'suzuki@jitsuflow.app', '090-3333-4444', '黒帯2段', 12, '元MMAファイター。実戦的な技術指導が得意。初心者指導も丁寧。', 1),
(3, '佐藤健', 'sato@jitsuflow.app', '090-5555-6666', '黒帯1段', 8, '競技柔術で数々の優勝経験。スポーツ科学を取り入れた指導法。', 1),
(4, '北野武', 'kitano@jitsuflow.app', '090-7777-8888', '茶帯', 5, '北海道柔術界の若手ホープ。情熱的な指導で人気。', 1),
(5, '田中美咲', 'tanaka@jitsuflow.app', '090-9999-0000', '紫帯', 4, '女性専用クラスも担当。きめ細やかな指導が好評。', 1);

-- Assign instructors to dojos (multiple assignments possible)
INSERT INTO instructor_dojos (instructor_id, dojo_id, role, start_date, is_active) VALUES
(1, 1, 'head_instructor', '2020-01-01', 1),
(1, 2, 'instructor', '2022-06-01', 1),
(2, 2, 'head_instructor', '2019-03-01', 1),
(3, 1, 'instructor', '2021-04-01', 1),
(3, 3, 'instructor', '2023-01-01', 1),
(4, 3, 'head_instructor', '2020-06-01', 1),
(5, 1, 'instructor', '2022-09-01', 1),
(5, 2, 'instructor', '2023-03-01', 1);