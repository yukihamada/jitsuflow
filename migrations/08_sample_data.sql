-- Sample data for JitsuFlow

-- Shop Products
INSERT INTO products (name, description, price, stock_quantity, category, image_url, is_active, created_at, updated_at) VALUES
('JitsuFlow Gi - White', 'Premium quality Brazilian Jiu-Jitsu gi made from 100% cotton. Lightweight and durable.', 15000, 50, 'gi', 'https://placehold.co/600x400?text=White+Gi', 1, datetime('now'), datetime('now')),
('JitsuFlow Gi - Blue', 'Competition-ready BJJ gi with reinforced stitching. IBJJF approved.', 16000, 30, 'gi', 'https://placehold.co/600x400?text=Blue+Gi', 1, datetime('now'), datetime('now')),
('JitsuFlow Gi - Black', 'Professional black BJJ gi with gold embroidery. Premium pearl weave.', 18000, 20, 'gi', 'https://placehold.co/600x400?text=Black+Gi', 1, datetime('now'), datetime('now')),
('Rash Guard - Short Sleeve', 'High-performance compression shirt for no-gi training. Quick-dry fabric.', 5000, 100, 'apparel', 'https://placehold.co/600x400?text=Rash+Guard', 1, datetime('now'), datetime('now')),
('Rash Guard - Long Sleeve', 'Full arm protection rashguard with anti-microbial treatment.', 6000, 75, 'apparel', 'https://placehold.co/600x400?text=Long+Sleeve+RG', 1, datetime('now'), datetime('now')),
('Fight Shorts', 'Durable grappling shorts with flexible waistband. Perfect for no-gi training.', 7000, 60, 'apparel', 'https://placehold.co/600x400?text=Fight+Shorts', 1, datetime('now'), datetime('now')),
('BJJ Belt - White', 'Official JitsuFlow white belt. 100% cotton, 4cm width.', 2000, 200, 'belt', 'https://placehold.co/600x400?text=White+Belt', 1, datetime('now'), datetime('now')),
('BJJ Belt - Blue', 'Official JitsuFlow blue belt. Premium quality cotton.', 2500, 150, 'belt', 'https://placehold.co/600x400?text=Blue+Belt', 1, datetime('now'), datetime('now')),
('BJJ Belt - Purple', 'Official JitsuFlow purple belt. Preshrunk cotton.', 2500, 100, 'belt', 'https://placehold.co/600x400?text=Purple+Belt', 1, datetime('now'), datetime('now')),
('BJJ Belt - Brown', 'Official JitsuFlow brown belt. Competition grade.', 2500, 50, 'belt', 'https://placehold.co/600x400?text=Brown+Belt', 1, datetime('now'), datetime('now')),
('BJJ Belt - Black', 'Official JitsuFlow black belt. Premium quality with gold bar.', 3000, 30, 'belt', 'https://placehold.co/600x400?text=Black+Belt', 1, datetime('now'), datetime('now')),
('Mouth Guard', 'Professional grade mouth guard with carrying case.', 1500, 200, 'protector', 'https://placehold.co/600x400?text=Mouth+Guard', 1, datetime('now'), datetime('now')),
('Knee Pads', 'Protective knee pads for intensive training. Set of 2.', 3500, 80, 'protector', 'https://placehold.co/600x400?text=Knee+Pads', 1, datetime('now'), datetime('now')),
('Training Bag', 'Large capacity BJJ gear bag with ventilated compartments.', 8000, 40, 'equipment', 'https://placehold.co/600x400?text=Training+Bag', 1, datetime('now'), datetime('now')),
('Water Bottle', 'JitsuFlow branded 1L water bottle. BPA-free.', 1200, 150, 'equipment', 'https://placehold.co/600x400?text=Water+Bottle', 1, datetime('now'), datetime('now'));

-- Rental Items
INSERT INTO rentals (item_type, item_name, size, color, condition, dojo_id, total_quantity, available_quantity, rental_price, deposit_amount, status, notes, created_at, updated_at) VALUES
('gi', 'Gi Rental - White', 'A2', 'white', 'good', 1, 20, 20, 500, 3000, 'available', 'Clean white gi available for daily rental', datetime('now'), datetime('now')),
('gi', 'Gi Rental - Blue', 'A2', 'blue', 'good', 1, 15, 15, 500, 3000, 'available', 'Clean blue gi for visitors and trial classes', datetime('now'), datetime('now')),
('other', 'Locker - Small', NULL, NULL, 'good', 1, 50, 45, 200, 0, 'available', 'Personal locker rental for storing valuables', datetime('now'), datetime('now')),
('other', 'Locker - Large', NULL, NULL, 'good', 1, 30, 25, 300, 0, 'available', 'Large locker for storing gi and gear', datetime('now'), datetime('now')),
('other', 'Private Mat Space', NULL, NULL, 'good', 1, 5, 5, 2000, 0, 'available', 'Private mat space rental per hour', datetime('now'), datetime('now'));

-- Note: Dojos are already inserted in initial schema, so we'll skip them

-- Sample Instructors
INSERT OR IGNORE INTO instructors (id, name, email, phone, belt_rank, bio, specialties, created_at, updated_at) VALUES
(1, 'Takeshi Yamamoto', 'yamamoto@jitsuflow.app', '090-1111-2222', 'black', 'Black belt with 15 years experience. Multiple-time national champion.', 'Guard passing, Competition preparation', datetime('now'), datetime('now')),
(2, 'Maria Santos', 'santos@jitsuflow.app', '090-3333-4444', 'black', 'IBJJF World Champion. Specializes in spider guard and berimbolo.', 'Spider guard, Berimbolo, Women''s self-defense', datetime('now'), datetime('now')),
(3, 'John Smith', 'smith@jitsuflow.app', '090-5555-6666', 'brown', 'Former MMA fighter turned BJJ instructor. No-gi specialist.', 'No-gi, Leg locks, MMA ground game', datetime('now'), datetime('now'));

-- Sample Videos (Free and Premium)
INSERT OR IGNORE INTO videos (id, title, description, video_url, thumbnail_url, duration, category, is_premium, created_at, updated_at) VALUES
(1, 'Basic Guard Pass', 'Learn the fundamentals of passing the closed guard.', 'https://example.com/video1', 'https://placehold.co/640x360?text=Guard+Pass', 600, 'technique', 0, datetime('now'), datetime('now')),
(2, 'Armbar from Guard', 'Master the classic armbar submission from closed guard.', 'https://example.com/video2', 'https://placehold.co/640x360?text=Armbar', 480, 'technique', 0, datetime('now'), datetime('now')),
(3, 'Advanced Berimbolo', 'Deep dive into the berimbolo technique for advanced students.', 'https://example.com/video3', 'https://placehold.co/640x360?text=Berimbolo', 900, 'technique', 1, datetime('now'), datetime('now')),
(4, 'Competition Mindset', 'Mental preparation strategies for BJJ competitions.', 'https://example.com/video4', 'https://placehold.co/640x360?text=Competition', 1200, 'mindset', 1, datetime('now'), datetime('now')),
(5, 'Warmup Routine', 'Complete 15-minute warmup routine for BJJ training.', 'https://example.com/video5', 'https://placehold.co/640x360?text=Warmup', 900, 'fitness', 0, datetime('now'), datetime('now'));