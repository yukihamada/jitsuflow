-- Sample rental items for JitsuFlow

-- Rental Items for each dojo
INSERT INTO rentals (item_type, item_name, size, color, condition, dojo_id, total_quantity, available_quantity, rental_price, deposit_amount, status, notes, created_at, updated_at) VALUES
-- Tokyo Main Dojo (ID: 1)
('gi', 'Gi Rental - White A1', 'A1', 'white', 'good', 1, 5, 5, 500, 3000, 'available', 'Clean white gi for daily rental', datetime('now'), datetime('now')),
('gi', 'Gi Rental - White A2', 'A2', 'white', 'good', 1, 10, 10, 500, 3000, 'available', 'Clean white gi for daily rental', datetime('now'), datetime('now')),
('gi', 'Gi Rental - White A3', 'A3', 'white', 'good', 1, 10, 10, 500, 3000, 'available', 'Clean white gi for daily rental', datetime('now'), datetime('now')),
('gi', 'Gi Rental - White A4', 'A4', 'white', 'good', 1, 5, 5, 500, 3000, 'available', 'Clean white gi for daily rental', datetime('now'), datetime('now')),
('gi', 'Gi Rental - Blue A2', 'A2', 'blue', 'good', 1, 8, 8, 500, 3000, 'available', 'Clean blue gi for visitors', datetime('now'), datetime('now')),
('gi', 'Gi Rental - Blue A3', 'A3', 'blue', 'good', 1, 7, 7, 500, 3000, 'available', 'Clean blue gi for visitors', datetime('now'), datetime('now')),
('belt', 'Belt Rental - White', NULL, 'white', 'good', 1, 20, 20, 100, 0, 'available', 'White belt for beginners', datetime('now'), datetime('now')),
('other', 'Locker - Small', NULL, NULL, 'good', 1, 50, 45, 200, 0, 'available', 'Personal locker rental', datetime('now'), datetime('now')),
('other', 'Locker - Large', NULL, NULL, 'good', 1, 30, 25, 300, 0, 'available', 'Large locker rental', datetime('now'), datetime('now'));

-- Additional rentals for Over Limit Sapporo (ID: 2) if it exists
INSERT OR IGNORE INTO rentals (item_type, item_name, size, color, condition, dojo_id, total_quantity, available_quantity, rental_price, deposit_amount, status, notes, created_at, updated_at) VALUES
('gi', 'Gi Rental - White A2', 'A2', 'white', 'good', 2, 5, 5, 500, 3000, 'available', 'Clean white gi for daily rental', datetime('now'), datetime('now')),
('gi', 'Gi Rental - White A3', 'A3', 'white', 'good', 2, 5, 5, 500, 3000, 'available', 'Clean white gi for daily rental', datetime('now'), datetime('now'));