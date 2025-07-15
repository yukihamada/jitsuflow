-- Clear existing instructor_dojos
DELETE FROM instructor_dojos;

-- Clear existing instructors
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
(13, '樋田', 'hida@yawara-bjj.com', NULL, '特別認定', 10, 'リラックスヒーリング専門セラピスト。', 1),
(14, '河野', 'kono@sweep-bjj.com', NULL, '黒帯2段', 12, 'SWEEP東京のメインインストラクター。スイープ技術のスペシャリスト。', 1),
(15, '野島', 'nojima@sweep-bjj.com', NULL, '黒帯1段', 8, 'SWEEP東京インストラクター。基礎技術指導に定評。', 1),
(16, '千春', 'chiharu@sweep-bjj.com', NULL, '茶帯', 6, 'SWEEP東京インストラクター。女性クラスも担当。', 1),
(17, '諸澤陽斗', 'morosawa@overlimit-bjj.com', NULL, '黒帯3段', 15, 'OverLimit札幌のヘッドインストラクター。北海道柔術界のリーダー的存在。', 1);