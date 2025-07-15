-- JitsuFlow 全商品統合（Sweep + YAWARA）
-- 既存商品を削除して、両ブランドの商品を追加

DELETE FROM products;

-- SWEEP/SIIIEEP™ 商品
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
('COTTON MOCK-NECK LS TEE', 'SIIIEEP™ コットンモックネックロングスリーブTシャツ。上品なモックネックデザインで、トレーニング後のカジュアルスタイルに最適。', 18000, 25, 'apparel', 'https://shop.sweep.love/cdn/shop/files/COTTONMOCKNECKLSTEE_01.png', 1, datetime('now'), datetime('now')),

-- YAWARA JIU-JITSU ACADEMY 商品
-- 道着シリーズ
('YAWARA Competition Gi - White A2', 'YAWARA JIU-JITSU ACADEMY 公式道着。競技用の高品質な白帯道着。550gsmパールウィーブ生地使用。IBJJF認定。', 22000, 25, 'gi', 'https://placehold.co/600x400?text=YAWARA+White+Gi+A2', 1, datetime('now'), datetime('now')),
('YAWARA Competition Gi - White A3', 'YAWARA JIU-JITSU ACADEMY 公式道着。競技用の高品質な白帯道着。550gsmパールウィーブ生地使用。IBJJF認定。', 22000, 25, 'gi', 'https://placehold.co/600x400?text=YAWARA+White+Gi+A3', 1, datetime('now'), datetime('now')),
('YAWARA Competition Gi - Blue A2', 'YAWARA JIU-JITSU ACADEMY 公式道着。競技用の高品質な青帯道着。550gsmパールウィーブ生地使用。IBJJF認定。', 24000, 20, 'gi', 'https://placehold.co/600x400?text=YAWARA+Blue+Gi+A2', 1, datetime('now'), datetime('now')),
('YAWARA Competition Gi - Blue A3', 'YAWARA JIU-JITSU ACADEMY 公式道着。競技用の高品質な青帯道着。550gsmパールウィーブ生地使用。IBJJF認定。', 24000, 20, 'gi', 'https://placehold.co/600x400?text=YAWARA+Blue+Gi+A3', 1, datetime('now'), datetime('now')),
('YAWARA Competition Gi - Black A2', 'YAWARA JIU-JITSU ACADEMY 公式道着。上級者向けの黒道着。金刺繍入り。550gsmパールウィーブ生地使用。', 26000, 15, 'gi', 'https://placehold.co/600x400?text=YAWARA+Black+Gi+A2', 1, datetime('now'), datetime('now')),
('YAWARA Competition Gi - Black A3', 'YAWARA JIU-JITSU ACADEMY 公式道着。上級者向けの黒道着。金刺繍入り。550gsmパールウィーブ生地使用。', 26000, 15, 'gi', 'https://placehold.co/600x400?text=YAWARA+Black+Gi+A3', 1, datetime('now'), datetime('now')),

-- ラッシュガード
('YAWARA Rash Guard - Short Sleeve Black M', 'YAWARA公式ラッシュガード。ノーギトレーニング用。吸汗速乾素材、UVカット機能付き。', 7500, 40, 'apparel', 'https://placehold.co/600x400?text=YAWARA+Rashguard+Black', 1, datetime('now'), datetime('now')),
('YAWARA Rash Guard - Short Sleeve Black L', 'YAWARA公式ラッシュガード。ノーギトレーニング用。吸汗速乾素材、UVカット機能付き。', 7500, 40, 'apparel', 'https://placehold.co/600x400?text=YAWARA+Rashguard+Black', 1, datetime('now'), datetime('now')),
('YAWARA Rash Guard - Long Sleeve Black M', 'YAWARA公式長袖ラッシュガード。肘まで保護。吸汗速乾素材、抗菌防臭加工。', 8500, 30, 'apparel', 'https://placehold.co/600x400?text=YAWARA+LS+Rashguard', 1, datetime('now'), datetime('now')),
('YAWARA Rash Guard - Long Sleeve Black L', 'YAWARA公式長袖ラッシュガード。肘まで保護。吸汗速乾素材、抗菌防臭加工。', 8500, 30, 'apparel', 'https://placehold.co/600x400?text=YAWARA+LS+Rashguard', 1, datetime('now'), datetime('now')),

-- ファイトショーツ
('YAWARA Fight Shorts - Black M', 'YAWARA公式ファイトショーツ。4ウェイストレッチ素材。サイドスリット入りで動きやすい設計。', 9000, 35, 'apparel', 'https://placehold.co/600x400?text=YAWARA+Fight+Shorts', 1, datetime('now'), datetime('now')),
('YAWARA Fight Shorts - Black L', 'YAWARA公式ファイトショーツ。4ウェイストレッチ素材。サイドスリット入りで動きやすい設計。', 9000, 35, 'apparel', 'https://placehold.co/600x400?text=YAWARA+Fight+Shorts', 1, datetime('now'), datetime('now')),
('YAWARA Fight Shorts - Black XL', 'YAWARA公式ファイトショーツ。4ウェイストレッチ素材。サイドスリット入りで動きやすい設計。', 9000, 25, 'apparel', 'https://placehold.co/600x400?text=YAWARA+Fight+Shorts', 1, datetime('now'), datetime('now')),

-- Tシャツ
('YAWARA Academy T-Shirt - Black M', 'YAWARA JIU-JITSU ACADEMY公式Tシャツ。コットン100%。アカデミーロゴプリント。', 4500, 50, 'apparel', 'https://placehold.co/600x400?text=YAWARA+T-Shirt+Black', 1, datetime('now'), datetime('now')),
('YAWARA Academy T-Shirt - Black L', 'YAWARA JIU-JITSU ACADEMY公式Tシャツ。コットン100%。アカデミーロゴプリント。', 4500, 50, 'apparel', 'https://placehold.co/600x400?text=YAWARA+T-Shirt+Black', 1, datetime('now'), datetime('now')),
('YAWARA Academy T-Shirt - White M', 'YAWARA JIU-JITSU ACADEMY公式Tシャツ。コットン100%。アカデミーロゴプリント。', 4500, 50, 'apparel', 'https://placehold.co/600x400?text=YAWARA+T-Shirt+White', 1, datetime('now'), datetime('now')),
('YAWARA Academy T-Shirt - White L', 'YAWARA JIU-JITSU ACADEMY公式Tシャツ。コットン100%。アカデミーロゴプリント。', 4500, 50, 'apparel', 'https://placehold.co/600x400?text=YAWARA+T-Shirt+White', 1, datetime('now'), datetime('now')),

-- アクセサリー
('YAWARA Academy Cap - Black', 'YAWARA JIU-JITSU ACADEMYキャップ。刺繍ロゴ入り。アジャスタブル。', 3800, 60, 'equipment', 'https://placehold.co/600x400?text=YAWARA+Cap+Black', 1, datetime('now'), datetime('now')),
('YAWARA Academy Cap - Navy', 'YAWARA JIU-JITSU ACADEMYキャップ。刺繍ロゴ入り。アジャスタブル。', 3800, 60, 'equipment', 'https://placehold.co/600x400?text=YAWARA+Cap+Navy', 1, datetime('now'), datetime('now')),
('YAWARA Gym Bag', 'YAWARA公式ジムバッグ。大容量40L。道着やトレーニング用品をまとめて収納。防水素材。', 12000, 25, 'equipment', 'https://placehold.co/600x400?text=YAWARA+Gym+Bag', 1, datetime('now'), datetime('now')),
('YAWARA Water Bottle - 1L', 'YAWARA公式ウォーターボトル。1リットル容量。BPAフリー。ロゴ入り。', 2500, 80, 'equipment', 'https://placehold.co/600x400?text=YAWARA+Water+Bottle', 1, datetime('now'), datetime('now')),

-- プロテクター
('YAWARA Mouth Guard - Clear', 'YAWARA公式マウスガード。医療グレードシリコン使用。ケース付き。', 2800, 100, 'protector', 'https://placehold.co/600x400?text=YAWARA+Mouth+Guard', 1, datetime('now'), datetime('now')),
('YAWARA Knee Pads - Black M/L', 'YAWARA公式ニーパッド。高密度フォーム使用。膝の保護に最適。', 4800, 50, 'protector', 'https://placehold.co/600x400?text=YAWARA+Knee+Pads', 1, datetime('now'), datetime('now')),
('YAWARA Ear Guards', 'YAWARA公式イヤーガード。柔術特有の耳の怪我を防止。調整可能。', 3600, 40, 'protector', 'https://placehold.co/600x400?text=YAWARA+Ear+Guards', 1, datetime('now'), datetime('now'));