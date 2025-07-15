-- Add instructors for SWEEP Tokyo and OverLimit Sapporo

-- Add new instructors
INSERT INTO instructors (id, name, email, phone, belt_rank, years_experience, bio, is_active) VALUES
(14, '河野', 'kono@sweep-bjj.com', NULL, '黒帯2段', 12, 'SWEEP東京のメインインストラクター。スイープ技術のスペシャリスト。', 1),
(15, '野島', 'nojima@sweep-bjj.com', NULL, '黒帯1段', 8, 'SWEEP東京インストラクター。基礎技術指導に定評。', 1),
(16, '千春', 'chiharu@sweep-bjj.com', NULL, '茶帯', 6, 'SWEEP東京インストラクター。女性クラスも担当。', 1),
(17, '諸澤陽斗', 'morosawa@overlimit-bjj.com', NULL, '黒帯3段', 15, 'OverLimit札幌のヘッドインストラクター。北海道柔術界のリーダー的存在。', 1);

-- Assign instructors to their dojos
INSERT INTO instructor_dojos (instructor_id, dojo_id, role, start_date, is_active) VALUES
-- SWEEP東京のインストラクター
(14, 2, 'head_instructor', '2017-09-01', 1),  -- 河野をSWEEP東京のヘッドに
(15, 2, 'instructor', '2019-04-01', 1),       -- 野島をSWEEP東京に
(16, 2, 'instructor', '2020-06-01', 1),       -- 千春をSWEEP東京に
-- OverLimit札幌のインストラクター
(17, 3, 'head_instructor', '2015-03-01', 1);  -- 諸澤陽斗をOverLimit札幌のヘッドに

-- 北野武を通常インストラクターに変更（諸澤陽斗がヘッドになるため）
UPDATE instructor_dojos 
SET role = 'instructor' 
WHERE instructor_id = 4 AND dojo_id = 3;