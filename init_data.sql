-- Insert sample users first
INSERT INTO users (email, password_hash, name, phone, created_at, updated_at) VALUES
('user@jitsuflow.app', '$2b$10$demo_hash_user', 'デモユーザー', '090-1234-5678', datetime('now'), datetime('now')),
('admin@jitsuflow.app', '$2b$10$demo_hash_admin', '管理者', '090-9999-0000', datetime('now'), datetime('now')),
('instructor@jitsuflow.app', '$2b$10$demo_hash_instructor', 'インストラクター太郎', '090-5555-1111', datetime('now'), datetime('now'));

-- Insert dojo data
INSERT INTO dojos (name, address, phone, email, website, description, instructor, pricing_info, booking_system) VALUES
('YAWARA JIU-JITSU ACADEMY', '東京都渋谷区神宮前1-8-10 The Ice Cubes 8-9F', NULL, NULL, 'https://jiujitsu.yawara.fit/', 'プレミアムウェルネス複合施設内の柔術アカデミー。現世界チャンピオンによる指導。', 'Ryozo Murata (村田良蔵)', 'なでしこプラン¥12,000/月、Yawara-8プラン¥22,000/月、フルタイムプラン¥33,000/月', 'リファーラル制'),
('Over Limit Sapporo', '北海道札幌市中央区南4条西1丁目15-2 栗林ビル3F', '011-522-9466', NULL, 'https://overlimit-sapporo.com/', '北海道初のブラジリアン柔術専門アカデミー。世界チャンピオンによる指導で150名以上の会員が在籍。', 'Ryozo Murata', 'フルタイム¥12,000/月、マンスリー5¥10,000/月、レディース&キッズ¥8,000/月', '電話・SNS'),
('スイープ', '東京都渋谷区千駄ヶ谷3-55-12 ヴィラパルテノン3F', NULL, NULL, NULL, '北参道駅徒歩3分の隠れ家的柔術道場。少人数制でアットホームな雰囲気。', 'スイープインストラクター', '月8回プラン¥22,000/月、通い放題プラン¥33,000/月', '直接連絡');

-- Insert class schedules for Over Limit Sapporo
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
('村田良蔵', 1, 'black', 1980, 'Yawara柔術アカデミー代表インストラクター。ブラジリアン柔術黒帯（グレイシー直系）でスポーツ柔術日本連盟の会長を務める。北海道出身者として初めてグレイシー一族直系の黒帯を取得。師匠はホイラー・グレイシー系黒帯のクリスチャーノ・カリオカ。', '["2018年SJJIF世界選手権マスター2黒帯フェザー級優勝", "2019年SJJIF世界選手権マスター2黒帯フェザー級優勝", "2013年アブダビワールドプロ日本予選ペナ級優勝"]', 1),
('濱田真亮', 1, 'black', 1978, 'Yawara柔術アカデミーインストラクター。2013年（35歳時）に柔術を始めた遅咲きの選手。出身は北海道で、村田良蔵の門下生として実力をつけた。各帯で好成績を収め、初心者にも分かりやすく丁寧な指導を心掛けている。', '["2015年DUMAU JIU-JITSU JAPAN CUPマスター2ライトフェザー級優勝（白帯）", "2019年SJJJF全日本マスター選手権ライトフェザー級優勝（青帯）", "2021年九州国際マスター選手権ライトフェザー級優勝（紫帯）"]', 0),

-- Over Limit instructors
('村田良蔵', 2, 'black', 1980, 'OVER LIMIT札幌代表取締役/ヘッドインストラクター。2018年、柔術仲間のエジソン先生との提携により札幌校を立ち上げた。「清潔でアットホームな空間で、本物のグレイシー柔術をファッショナブルに伝えたい」という理念のもと道場を運営。', '["2018年SJJIF世界選手権マスター2黒帯フェザー級優勝", "2019年SJJIF世界選手権マスター2黒帯フェザー級優勝"]', 1),
('諸澤陽斗', 2, 'black', 2000, 'インストラクター（黒帯）。2016年から柔術を始め、村田代表の薫陶を受け急成長した新鋭。圧倒的なフットワークとガードワークを武器とする。「柔術は終わりが無いからずっと楽しめる」とその魅力を語る。', '["2018年北海道選手権76kg級＆無差別級優勝", "2019年ASJJF関東選手権70kg級優勝", "2019年SJJIF世界選手権-64kg級準優勝", "2023年JBJJF全日本選手権ライト級優勝"]', 0),
('佐藤正幸', 2, 'purple', 1980, 'インストラクター（紫帯）。2018年より柔術を始め、ダイエット目的で取り組む中で2ヶ月で13kg減量に成功。物腰柔らかで面倒見が良く、初心者クラスを中心に「とにかくわかりやすく楽しんでもらう」指導を心掛けている。', '["2023年 第3回 Reversal Cup札幌 ライトフェザー級 優勝"]', 0),
('堰本祐希', 2, 'purple', 1999, 'インストラクター（紫帯）。2021年に柔術を開始し、わずか数年で頭角を現した若手有望株。軽量級ながら高い技術と戦略で勝負するスタイル。「体が大きくなくても強くなれる」の体現者として指導。', '["2023年 第3回 Reversal Cup札幌ライトフェザー級＆無差別級優勝", "2024年 SJJIF世界選手権ライトフェザー級3位", "2024年 Copa Alma北海道大会ライトフェザー級優勝"]', 0),
('立石修也', 2, 'brown', NULL, 'OVER LIMIT札幌のインストラクター。実力派の茶帯として道場の指導陣を支える。', '[]', 0),

-- SWEEP instructors  
('村田良蔵', 3, 'black', 1980, '2025年7月に開設されたSWEEP柔術アカデミーでも指導を担当。「初心者が柔術のダイナミズムを体感し自分の強みを再発見できる場を提供したい」とメッセージを寄せている。', '["2018年SJJIF世界選手権マスター2黒帯フェザー級優勝", "2019年SJJIF世界選手権マスター2黒帯フェザー級優勝"]', 0),
('廣鰭翔大', 3, 'brown', 1992, 'SWEEP柔術アカデミーのヘッドインストラクター。スポーツ柔術日本連盟副理事長も務める。2011年に大学で柔術を始め、運動音痴だった自身を変えるべく稽古に励んだ経験を持つ。「初めての方でも安全に楽しく柔術を通じて日常が豊かになる体験を提供したい」と語る。', '["第10回北海道選手権ルースター級＆無差別級優勝（青帯）", "2017年ASJJF DUMAU Korea Grand Prixルースター級優勝", "2022年リカルド・デラヒーバCupマスター1ルースター級優勝"]', 1);

-- Insert videos with real data
INSERT INTO videos (id, title, description, is_premium, category, upload_url, thumbnail_url, duration, views, status, uploaded_by, created_at, updated_at) VALUES
('video-1', '【初心者必見】クローズドガードの基本', '柔術の基本中の基本、クローズドガードの正しいポジションと基本的な動きを村田良蔵が詳しく解説。初心者が最初に覚えるべき重要なポジションです。', 0, 'basics', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg', 780, 2453, 'published', 1, datetime('now', '-15 days'), datetime('now', '-15 days')),
('video-2', '柔術の基本エチケットとマナー', '道場での基本的なエチケットと礼儀作法について。初心者が知っておくべき柔術コミュニティでのマナーを解説します。', 0, 'basics', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/ElephantsDream.jpg', 420, 1876, 'published', 1, datetime('now', '-12 days'), datetime('now', '-12 days')),
('video-3', 'パスガードの基本動作', '相手のガードを通過するための基本的な考え方と動作。廣鰭翔大が実演する効果的なパスガードテクニック。', 0, 'basics', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerBlazes.jpg', 920, 3241, 'published', 1, datetime('now', '-10 days'), datetime('now', '-10 days')),
('video-4', '【プレミアム】ベリンボロシステム完全解説', '現代柔術の代表的なテクニック、ベリンボロの基本から応用まで徹底解説。村田良蔵の実戦経験を基にした実用的なアプローチ。', 1, 'advanced', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerEscapes.jpg', 1620, 892, 'published', 1, datetime('now', '-8 days'), datetime('now', '-8 days')),
('video-5', '【プレミアム】ラペラガードマスタークラス', '諸澤陽斗によるラペラガードの高度なテクニック集。JBJJF全日本選手権優勝者の技術を学ぶプレミアムコンテンツ。', 1, 'advanced', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerFun.jpg', 1980, 645, 'published', 1, datetime('now', '-6 days'), datetime('now', '-6 days')),
('video-6', '【プレミアム】サブミッション連携システム', '実戦で使える効果的なサブミッション連携。一つの動きから複数のサブミッションへ繋げる高度なテクニック。', 1, 'submissions', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerJoyrides.jpg', 2100, 723, 'published', 1, datetime('now', '-4 days'), datetime('now', '-4 days')),
('video-7', '試合で勝つためのメンタル準備', '世界選手権優勝者村田良蔵による試合前の心構えとメンタル準備法。試合で実力を発揮するためのコツ。', 0, 'competition', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerMeltdowns.jpg', 540, 1987, 'published', 1, datetime('now', '-3 days'), datetime('now', '-3 days')),
('video-8', '【プレミアム】試合戦術とゲームプラン', '試合での具体的な戦術とゲームプランの立て方。相手のタイプ別対策と効果的なポイント戦略。', 1, 'competition', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/Sintel.jpg', 1440, 567, 'published', 1, datetime('now', '-2 days'), datetime('now', '-2 days')),
('video-9', '女性のための柔術テクニック', '女性特有の体型と筋力を活かした効果的な柔術テクニック。初心者女性にも分かりやすく解説。', 0, 'basics', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/SubaruOutbackOnStreetAndDirt.jpg', 720, 1432, 'published', 1, datetime('now', '-1 days'), datetime('now', '-1 days')),
('video-10', '【プレミアム】マスター技術解説シリーズ', '黒帯マスターによる高度な技術解説。細かなディテールと実戦での応用法まで詳しく解説。', 1, 'advanced', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/TearsOfSteel.jpg', 2520, 398, 'published', 1, datetime('now'), datetime('now'));