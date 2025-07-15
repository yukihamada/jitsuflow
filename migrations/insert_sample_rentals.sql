-- Insert Sample Rentals for JitsuFlow Dojos
-- This migration inserts sample rental items from sampleRentals.js

-- Note: This assumes dojos with IDs 1, 2, and 3 exist in the dojos table
-- If they don't exist, you'll need to insert them first or update the dojo_id values

-- Dojo 1 (YAWARA) Rental Items

-- Gi Rentals for Dojo 1
INSERT INTO rentals (item_type, item_name, size, color, condition, dojo_id, total_quantity, available_quantity, rental_price, deposit_amount, status, notes) VALUES
('gi', '道着（白帯用）', 'A0', 'white', 'good', 1, 3, 3, 1000, 5000, 'available', '初心者向けの清潔な道着。毎回洗濯済み。'),
('gi', '道着（白帯用）', 'A1', 'white', 'good', 1, 5, 5, 1000, 5000, 'available', '標準サイズの道着。快適な着心地。'),
('gi', '道着（白帯用）', 'A2', 'white', 'good', 1, 5, 4, 1000, 5000, 'available', '人気のサイズ。早めの予約推奨。'),
('gi', '道着（白帯用）', 'A3', 'white', 'good', 1, 4, 4, 1000, 5000, 'available', '大きめサイズの道着。'),
('gi', '道着（白帯用）', 'A4', 'white', 'good', 1, 2, 2, 1000, 5000, 'available', '特大サイズ。在庫限定。'),
('gi', '道着（色帯用）', 'A2', 'blue', 'excellent', 1, 2, 2, 1500, 8000, 'available', 'IBJJF認定の試合用道着。');

-- Belt Rentals for Dojo 1
INSERT INTO rentals (item_type, item_name, size, color, condition, dojo_id, total_quantity, available_quantity, rental_price, deposit_amount, status, notes) VALUES
('belt', '白帯', 'A1', 'white', 'good', 1, 10, 8, 300, 1000, 'available', '初心者用の白帯。'),
('belt', '白帯', 'A2', 'white', 'good', 1, 10, 9, 300, 1000, 'available', '標準サイズの白帯。'),
('belt', '青帯', 'A2', 'blue', 'good', 1, 5, 5, 500, 2000, 'available', '青帯ランク用。');

-- Rashguard Rentals for Dojo 1
INSERT INTO rentals (item_type, item_name, size, color, condition, dojo_id, total_quantity, available_quantity, rental_price, deposit_amount, status, notes) VALUES
('rashguard', 'ラッシュガード（長袖）', 'S', 'black', 'good', 1, 3, 3, 800, 3000, 'available', 'ノーギ練習用。UVカット機能付き。'),
('rashguard', 'ラッシュガード（長袖）', 'M', 'black', 'good', 1, 5, 4, 800, 3000, 'available', '人気の標準サイズ。'),
('rashguard', 'ラッシュガード（長袖）', 'L', 'black', 'good', 1, 5, 5, 800, 3000, 'available', '大きめサイズ。快適な着心地。'),
('rashguard', 'ラッシュガード（長袖）', 'XL', 'black', 'good', 1, 3, 3, 800, 3000, 'available', '特大サイズ。');

-- Fight Shorts Rentals for Dojo 1
INSERT INTO rentals (item_type, item_name, size, color, condition, dojo_id, total_quantity, available_quantity, rental_price, deposit_amount, status, notes) VALUES
('shorts', 'ファイトショーツ', '30', 'black', 'good', 1, 3, 3, 700, 2500, 'available', 'ノーギ用ショーツ。動きやすい設計。'),
('shorts', 'ファイトショーツ', '32', 'black', 'good', 1, 5, 4, 700, 2500, 'available', '標準サイズ。人気商品。'),
('shorts', 'ファイトショーツ', '34', 'black', 'good', 1, 4, 4, 700, 2500, 'available', '大きめサイズ。');

-- Protector Rentals for Dojo 1
INSERT INTO rentals (item_type, item_name, size, color, condition, dojo_id, total_quantity, available_quantity, rental_price, deposit_amount, status, notes) VALUES
('protector', 'マウスガード', 'one_size', 'clear', 'new', 1, 20, 18, 500, 1500, 'available', '新品の成型タイプ。衛生的。'),
('protector', 'イヤーガード', 'one_size', 'black', 'good', 1, 10, 9, 600, 2000, 'available', '耳の保護用。調整可能。');

-- Dojo 2 (Over Limit Sapporo) Rental Items
INSERT INTO rentals (item_type, item_name, size, color, condition, dojo_id, total_quantity, available_quantity, rental_price, deposit_amount, status, notes) VALUES
('gi', '道着（白帯用）', 'A1', 'white', 'good', 2, 4, 4, 1000, 5000, 'available', 'Over Limit Sapporo専用道着。'),
('gi', '道着（白帯用）', 'A2', 'white', 'good', 2, 6, 5, 1000, 5000, 'available', '人気サイズ。清潔管理徹底。'),
('gi', '道着（白帯用）', 'A3', 'white', 'good', 2, 3, 3, 1000, 5000, 'available', '大きめサイズ完備。');

-- Dojo 3 (スイープ道場) Rental Items
INSERT INTO rentals (item_type, item_name, size, color, condition, dojo_id, total_quantity, available_quantity, rental_price, deposit_amount, status, notes) VALUES
('gi', '道着（白帯用）', 'A0', 'white', 'excellent', 3, 2, 2, 1200, 6000, 'available', 'スイープ道場プレミアム道着。'),
('gi', '道着（白帯用）', 'A1', 'white', 'excellent', 3, 4, 4, 1200, 6000, 'available', '高品質道着。快適性重視。'),
('gi', '道着（白帯用）', 'A2', 'white', 'excellent', 3, 4, 3, 1200, 6000, 'available', 'プレミアム仕様。試合でも使用可。'),
('rashguard', 'ラッシュガード（長袖）', 'M', 'navy', 'excellent', 3, 4, 4, 1000, 4000, 'available', 'スイープオリジナルデザイン。'),
('rashguard', 'ラッシュガード（長袖）', 'L', 'navy', 'excellent', 3, 4, 3, 1000, 4000, 'available', '高品質素材使用。');