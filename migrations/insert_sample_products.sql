-- Insert Sample Products for JitsuFlow Shop
-- This migration inserts sample products from sampleProducts.js

-- Clear existing sample products (optional - remove this line in production)
-- DELETE FROM products WHERE category NOT IN ('training', 'healing', 'bjj_training', 'rental', 'trial', 'other');

-- Insert Gi (道着) products
INSERT INTO products (name, description, price, category, image_url, stock_quantity, is_active, size, color, attributes) VALUES
('YAWARA プレミアム道着', '最高級コットン100%使用の高品質道着。試合規定対応。耐久性と快適性を両立。', 18000, 'gi', 'https://images.unsplash.com/photo-1604009506606-fd4989d50e6d?w=800', 12, 1, 'A2', 'white', '{"material":"コットン100%","weight":"550gsm","certification":"IBJJF認定"}'),
('プレミアム道着（紺色）', '試合用紺色道着。IBJJF認定済み。最高品質の素材を使用。', 22000, 'gi', 'https://images.unsplash.com/photo-1604009506606-fd4989d50e6d?w=800', 8, 1, 'A3', 'navy', '{"material":"コットン100%","weight":"550gsm","certification":"IBJJF認定"}'),
('軽量道着（夏用）', '通気性に優れた軽量道着。暑い季節のトレーニングに最適。', 15000, 'gi', 'https://images.unsplash.com/photo-1604009506606-fd4989d50e6d?w=800', 15, 1, 'A1', 'white', '{"material":"コットン/ポリエステル混紡","weight":"400gsm","season":"夏用"}');

-- Insert Belt (帯) products
INSERT INTO products (name, description, price, category, image_url, stock_quantity, is_active, size, color, attributes) VALUES
('白帯 A2サイズ', '初心者向け白帯。IBJJF規定準拠。耐久性のある厚手素材。', 2500, 'belt', 'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=800', 30, 1, 'A2', 'white', '{"width":"4cm","material":"コットン100%"}'),
('青帯 A3サイズ', '青帯ランク用。耐久性と見た目の美しさを両立。', 4500, 'belt', 'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=800', 18, 1, 'A3', 'blue', '{"width":"4cm","material":"コットン100%"}'),
('紫帯 A2サイズ', '紫帯ランク用。高品質素材使用の上級者向け帯。', 6000, 'belt', 'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=800', 10, 1, 'A2', 'purple', '{"width":"4cm","material":"コットン100%"}'),
('茶帯 A2サイズ', '茶帯ランク用。職人の手による高品質仕上げ。', 7500, 'belt', 'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=800', 5, 1, 'A2', 'brown', '{"width":"4cm","material":"コットン100%"}'),
('ブラック帯 A2サイズ', 'IBJJF認定黒帯。最高級素材使用、耐久性に優れた高品質仕上げ。', 8500, 'belt', 'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=800', 8, 1, 'A2', 'black', '{"width":"4cm","material":"コットン100%","certification":"IBJJF認定"}');

-- Insert Protector (プロテクター) products
INSERT INTO products (name, description, price, category, image_url, stock_quantity, is_active, size, color, attributes) VALUES
('プロ仕様マウスガード', '成型可能タイプのマウスガード。安全性を重視した設計。', 2800, 'protector', 'https://images.unsplash.com/photo-1609205807107-454f1c1f4a60?w=800', 25, 1, NULL, 'clear', '{"type":"成型タイプ","material":"EVA素材"}'),
('イヤーガード', '耳を保護するイヤーガード。長時間の練習でも快適。', 3500, 'protector', 'https://images.unsplash.com/photo-1609205807107-454f1c1f4a60?w=800', 15, 1, NULL, 'black', '{"type":"ソフトタイプ","material":"ネオプレーン"}'),
('ニーパッド（膝サポーター）', '膝を保護する高品質サポーター。動きを妨げない設計。', 4200, 'protector', 'https://images.unsplash.com/photo-1609205807107-454f1c1f4a60?w=800', 20, 1, 'M', 'black', '{"type":"圧縮サポート","material":"ライクラ/ネオプレーン"}');

-- Insert Apparel (アパレル) products
INSERT INTO products (name, description, price, category, image_url, stock_quantity, is_active, size, color, attributes) VALUES
('JitsuFlow Tシャツ', '吸湿速乾素材使用のトレーニングTシャツ。快適な着心地。', 3500, 'apparel', 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=800', 15, 1, 'L', 'black', '{"material":"ポリエステル100%","feature":"速乾性"}'),
('ラッシュガード 長袖', 'UVカット機能付き長袖ラッシュガード。ノーギ練習に最適。', 5800, 'apparel', 'https://images.unsplash.com/photo-1556906781-9a412961c28c?w=800', 20, 1, 'M', 'navy', '{"material":"ポリエステル/スパンデックス","uvProtection":"UPF50+"}'),
('グラップリングショーツ', '動きやすさを追求したファイトショーツ。耐久性抜群。', 6500, 'apparel', 'https://images.unsplash.com/photo-1519861531473-9200262188bf?w=800', 18, 1, '32', 'black', '{"material":"ポリエステル/スパンデックス","closure":"ベルクロ+紐"}'),
('スパッツ（コンプレッション）', '筋肉をサポートするコンプレッションスパッツ。', 4800, 'apparel', 'https://images.unsplash.com/photo-1556906781-9a412961c28c?w=800', 22, 1, 'M', 'black', '{"material":"ポリエステル/スパンデックス","compression":"中圧"}');

-- Insert Equipment (器具) products
INSERT INTO products (name, description, price, category, image_url, stock_quantity, is_active, size, color, attributes) VALUES
('グラップリングダミー', '自宅練習用グラップリングダミー。70kg相当の重量。', 28000, 'equipment', 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800', 3, 1, NULL, NULL, '{"weight":"70kg","height":"180cm","material":"合成皮革"}'),
('柔術マット 40mm厚', '高品質EVA素材の柔術専用マット。ジム品質の衝撃吸収。', 15000, 'equipment', 'https://images.unsplash.com/photo-1599058945522-28d584b6f0ff?w=800', 7, 1, NULL, NULL, '{"size":"100cm x 100cm","thickness":"40mm","material":"EVA"}'),
('レジスタンスバンドセット', '柔術トレーニング用レジスタンスバンド5本セット。', 8500, 'equipment', 'https://images.unsplash.com/photo-1598289431512-b97b0917affc?w=800', 12, 1, NULL, NULL, '{"resistance":"5-50kg","quantity":"5本","material":"ラテックス"}');

-- Add supplement category to products table (if not already added)
-- Note: This requires modifying the CHECK constraint. In production, this should be done in a separate migration

-- Insert Supplement (サプリメント) products
-- Note: These will only work if 'supplement' category is added to the CHECK constraint
-- For now, we'll skip these or add them as 'other' category
INSERT INTO products (name, description, price, category, image_url, stock_quantity, is_active, size, color, attributes) VALUES
('ホエイプロテイン（バニラ）', '高品質ホエイプロテイン。筋肉回復をサポート。', 5000, 'other', 'https://images.unsplash.com/photo-1593095948071-474c5cc2989d?w=800', 20, 1, NULL, NULL, '{"flavor":"バニラ","weight":"1kg","servings":"30回分","type":"supplement"}'),
('BCAA（レモン味）', '疲労回復をサポートするBCAA。トレーニング中の摂取に最適。', 3800, 'other', 'https://images.unsplash.com/photo-1593095948071-474c5cc2989d?w=800', 25, 1, NULL, NULL, '{"flavor":"レモン","weight":"500g","ratio":"2:1:1","type":"supplement"}'),
('クレアチン', '瞬発力向上をサポート。純度99.9%のクレアチンモノハイドレート。', 2800, 'other', 'https://images.unsplash.com/photo-1593095948071-474c5cc2989d?w=800', 18, 1, NULL, NULL, '{"type":"モノハイドレート","weight":"300g","purity":"99.9%","category":"supplement"}');

-- Insert Accessories (アクセサリー) products
-- Note: These will be added as 'other' category since 'accessories' is not in the CHECK constraint
INSERT INTO products (name, description, price, category, image_url, stock_quantity, is_active, size, color, attributes) VALUES
('道着バッグ', '道着専用の大容量バッグ。通気性の良いメッシュポケット付き。', 4500, 'other', 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=800', 15, 1, NULL, 'black', '{"capacity":"45L","material":"ナイロン","features":"防水加工","type":"accessories"}'),
('フィンガーテープ', '指の保護用テープ。粘着力が強く、剥がれにくい。', 800, 'other', 'https://images.unsplash.com/photo-1609205807107-454f1c1f4a60?w=800', 50, 1, NULL, NULL, '{"width":"1.3cm","length":"13.7m","quantity":"1ロール","type":"accessories"}'),
('タオル（速乾性）', '速乾性マイクロファイバータオル。コンパクトで持ち運び便利。', 1500, 'other', 'https://images.unsplash.com/photo-1611088147698-7f54a818df7e?w=800', 30, 1, NULL, 'gray', '{"size":"80cm x 40cm","material":"マイクロファイバー","feature":"抗菌加工","type":"accessories"}');