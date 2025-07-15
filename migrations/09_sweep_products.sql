-- Sweep shop products for JitsuFlow
-- 既存の商品を削除してSweepの商品で置き換え
DELETE FROM products;

-- Sweep shop products
INSERT INTO products (name, description, price, stock_quantity, category, image_url, is_active, created_at, updated_at) VALUES
-- バックパック
('BACKPACK 22L', 'SIIIEEP™ オフィシャル バックパック 22L。デイリーユースに最適なサイズ。耐久性の高い素材を使用し、複数のポケットで収納力抜群。', 28000, 20, 'equipment', 'https://shop.sweep.love/cdn/shop/files/1_e385e072-ac5d-45c9-8266-00815f53f8bb.png', 1, datetime('now'), datetime('now')),
('BACKPACK 35L', 'SIIIEEP™ オフィシャル バックパック 35L。遠征や合宿に最適な大容量サイズ。道着やトレーニングギアをまとめて収納可能。', 35200, 15, 'equipment', 'https://shop.sweep.love/cdn/shop/files/BACKPACK_01.png', 1, datetime('now'), datetime('now')),

-- アクセサリー
('CAP - Black', 'SIIIEEP™ ロゴキャップ ブラック。コットン100%で快適な着用感。トレーニング後のカジュアルスタイルに。', 5500, 50, 'equipment', 'https://shop.sweep.love/cdn/shop/files/COTTONLOGOCAP_01.png', 1, datetime('now'), datetime('now')),
('CAP - White', 'SIIIEEP™ ロゴキャップ ホワイト。コットン100%で快適な着用感。清潔感のあるホワイトカラー。', 5500, 50, 'equipment', 'https://shop.sweep.love/cdn/shop/files/COTTONLOGOCAP_01.png', 1, datetime('now'), datetime('now')),

-- Tシャツ
('COTTON LOGO TEE - Black S', 'SIIIEEP™ コットンロゴTシャツ ブラック Sサイズ。高品質コットン100%使用。トレーニング後のリラックスタイムに最適。', 9900, 30, 'apparel', 'https://shop.sweep.love/cdn/shop/files/COTTONLOGOTEE_01.png', 1, datetime('now'), datetime('now')),
('COTTON LOGO TEE - Black M', 'SIIIEEP™ コットンロゴTシャツ ブラック Mサイズ。高品質コットン100%使用。', 9900, 30, 'apparel', 'https://shop.sweep.love/cdn/shop/files/COTTONLOGOTEE_01.png', 1, datetime('now'), datetime('now')),
('COTTON LOGO TEE - Black L', 'SIIIEEP™ コットンロゴTシャツ ブラック Lサイズ。高品質コットン100%使用。', 9900, 30, 'apparel', 'https://shop.sweep.love/cdn/shop/files/COTTONLOGOTEE_01.png', 1, datetime('now'), datetime('now')),
('COTTON LOGO TEE - Black XL', 'SIIIEEP™ コットンロゴTシャツ ブラック XLサイズ。高品質コットン100%使用。', 9900, 20, 'apparel', 'https://shop.sweep.love/cdn/shop/files/COTTONLOGOTEE_01.png', 1, datetime('now'), datetime('now')),
('COTTON LOGO TEE - White S', 'SIIIEEP™ コットンロゴTシャツ ホワイト Sサイズ。高品質コットン100%使用。清潔感のあるホワイトカラー。', 9900, 30, 'apparel', 'https://shop.sweep.love/cdn/shop/files/COTTONLOGOTEE_01.png', 1, datetime('now'), datetime('now')),
('COTTON LOGO TEE - White M', 'SIIIEEP™ コットンロゴTシャツ ホワイト Mサイズ。高品質コットン100%使用。', 9900, 30, 'apparel', 'https://shop.sweep.love/cdn/shop/files/COTTONLOGOTEE_01.png', 1, datetime('now'), datetime('now')),
('COTTON LOGO TEE - White L', 'SIIIEEP™ コットンロゴTシャツ ホワイト Lサイズ。高品質コットン100%使用。', 9900, 30, 'apparel', 'https://shop.sweep.love/cdn/shop/files/COTTONLOGOTEE_01.png', 1, datetime('now'), datetime('now')),
('COTTON LOGO TEE - White XL', 'SIIIEEP™ コットンロゴTシャツ ホワイト XLサイズ。高品質コットン100%使用。', 9900, 20, 'apparel', 'https://shop.sweep.love/cdn/shop/files/COTTONLOGOTEE_01.png', 1, datetime('now'), datetime('now')),

-- ロングスリーブ
('COTTON LS TEE - Heather Gray M', 'SIIIEEP™ コットンロングスリーブTシャツ ヘザーグレー Mサイズ。オールシーズン着用可能な長袖Tシャツ。', 18000, 20, 'apparel', 'https://shop.sweep.love/cdn/shop/files/ITEM_0111_01_1c82cb42-11bd-4e92-98b9-1efcf9392da5.png', 1, datetime('now'), datetime('now')),
('COTTON LS TEE - Heather Gray L', 'SIIIEEP™ コットンロングスリーブTシャツ ヘザーグレー Lサイズ。', 18000, 20, 'apparel', 'https://shop.sweep.love/cdn/shop/files/ITEM_0111_01_1c82cb42-11bd-4e92-98b9-1efcf9392da5.png', 1, datetime('now'), datetime('now')),
('COTTON LS TEE - Heather Gray XL', 'SIIIEEP™ コットンロングスリーブTシャツ ヘザーグレー XLサイズ。', 18000, 15, 'apparel', 'https://shop.sweep.love/cdn/shop/files/ITEM_0111_01_1c82cb42-11bd-4e92-98b9-1efcf9392da5.png', 1, datetime('now'), datetime('now')),
('COTTON LS TEE - Beige M', 'SIIIEEP™ コットンロングスリーブTシャツ ベージュ Mサイズ。ナチュラルな色合いでどんなスタイルにも合わせやすい。', 18000, 20, 'apparel', 'https://shop.sweep.love/cdn/shop/files/ITEM_0111_01_1c82cb42-11bd-4e92-98b9-1efcf9392da5.png', 1, datetime('now'), datetime('now')),
('COTTON LS TEE - Beige L', 'SIIIEEP™ コットンロングスリーブTシャツ ベージュ Lサイズ。', 18000, 20, 'apparel', 'https://shop.sweep.love/cdn/shop/files/ITEM_0111_01_1c82cb42-11bd-4e92-98b9-1efcf9392da5.png', 1, datetime('now'), datetime('now')),
('COTTON LS TEE - Beige XL', 'SIIIEEP™ コットンロングスリーブTシャツ ベージュ XLサイズ。', 18000, 15, 'apparel', 'https://shop.sweep.love/cdn/shop/files/ITEM_0111_01_1c82cb42-11bd-4e92-98b9-1efcf9392da5.png', 1, datetime('now'), datetime('now')),
('COTTON LS TEE - Black M', 'SIIIEEP™ コットンロングスリーブTシャツ ブラック Mサイズ。シックなブラックカラーで様々なシーンで活躍。', 18000, 20, 'apparel', 'https://shop.sweep.love/cdn/shop/files/ITEM_0111_01_1c82cb42-11bd-4e92-98b9-1efcf9392da5.png', 1, datetime('now'), datetime('now')),
('COTTON LS TEE - Black L', 'SIIIEEP™ コットンロングスリーブTシャツ ブラック Lサイズ。', 18000, 20, 'apparel', 'https://shop.sweep.love/cdn/shop/files/ITEM_0111_01_1c82cb42-11bd-4e92-98b9-1efcf9392da5.png', 1, datetime('now'), datetime('now')),
('COTTON LS TEE - Black XL', 'SIIIEEP™ コットンロングスリーブTシャツ ブラック XLサイズ。', 18000, 15, 'apparel', 'https://shop.sweep.love/cdn/shop/files/ITEM_0111_01_1c82cb42-11bd-4e92-98b9-1efcf9392da5.png', 1, datetime('now'), datetime('now')),

-- モックネック
('COTTON MOCK-NECK LS TEE', 'SIIIEEP™ コットンモックネックロングスリーブTシャツ。上品なモックネックデザインで、トレーニング後のカジュアルスタイルに最適。', 18000, 25, 'apparel', 'https://shop.sweep.love/cdn/shop/files/COTTONMOCKNECKLSTEE_01.png', 1, datetime('now'), datetime('now'));