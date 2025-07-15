-- Insert dojo data
INSERT INTO dojos (name, description, city, address, phone, stripe_account_id, lat, lng, created_at, updated_at) VALUES
('YAWARA道場', 'YAWARAブランドの総本山。初心者から上級者まで幅広く対応。最新設備を完備し、プロフェッショナルな指導を提供。', '東京', '東京都渋谷区道玄坂1-15-3', '03-1234-5678', NULL, 35.658584, 139.699730, datetime('now'), datetime('now')),
('SWEEP道場', 'SWEEP愛好者が集まる専門道場。テクニカルな技術指導に定評があり、競技者育成にも力を入れています。', '東京', '東京都港区赤坂3-21-10', '03-2345-6789', NULL, 35.675888, 139.736494, datetime('now'), datetime('now')),
('OverLimit道場', '限界を超える、をモットーに激しいトレーニングを提供。アスリート向けの本格的な道場。', '東京', '東京都新宿区歌舞伎町2-19-13', '03-3456-7890', NULL, 35.695798, 139.703657, datetime('now'), datetime('now')),
('札幌柔術アカデミー', '北海道最大級の柔術道場。広々とした施設で、初心者にも優しい指導が特徴。冬季も快適な室内環境。', '札幌', '北海道札幌市中央区南3条西5丁目1-1', '011-123-4567', NULL, 43.055969, 141.345183, datetime('now'), datetime('now'));