-- Products and Orders Migration
-- JitsuFlow Shop functionality

-- Products table
CREATE TABLE IF NOT EXISTS products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  description TEXT,
  price REAL NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('gi', 'belt', 'protector', 'apparel', 'equipment')),
  image_url TEXT,
  stock_quantity INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1,
  size TEXT,
  color TEXT,
  attributes TEXT, -- JSON string for additional attributes
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Shopping cart table (persisted cart)
CREATE TABLE IF NOT EXISTS shopping_carts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  product_id INTEGER NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
  UNIQUE(user_id, product_id)
);

-- Orders table
CREATE TABLE IF NOT EXISTS orders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  subtotal REAL NOT NULL,
  tax REAL NOT NULL,
  total REAL NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')),
  shipping_address TEXT,
  tracking_number TEXT,
  stripe_payment_id TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  shipped_at DATETIME,
  delivered_at DATETIME,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Order items table
CREATE TABLE IF NOT EXISTS order_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  order_id INTEGER NOT NULL,
  product_id INTEGER NOT NULL,
  product_name TEXT NOT NULL, -- Denormalized for history
  unit_price REAL NOT NULL, -- Denormalized for history
  quantity INTEGER NOT NULL,
  total_price REAL NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(id)
);

-- Indexes
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_active ON products(is_active);
CREATE INDEX idx_shopping_carts_user ON shopping_carts(user_id);
CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_order_items_order ON order_items(order_id);

-- Triggers
CREATE TRIGGER update_products_timestamp 
AFTER UPDATE ON products
BEGIN
  UPDATE products SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER update_shopping_carts_timestamp 
AFTER UPDATE ON shopping_carts
BEGIN
  UPDATE shopping_carts SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

-- Sample products
INSERT INTO products (name, description, price, category, stock_quantity, size, color) VALUES
('JitsuFlow 柔術道着 A2', '高品質な柔術専用道着。耐久性に優れ、競技にも練習にも最適。', 15000, 'gi', 10, 'A2', 'ホワイト'),
('JitsuFlow 柔術道着 A3', '高品質な柔術専用道着。耐久性に優れ、競技にも練習にも最適。', 15000, 'gi', 8, 'A3', 'ホワイト'),
('JitsuFlow 柔術道着 A2', '高品質な柔術専用道着。耐久性に優れ、競技にも練習にも最適。', 15000, 'gi', 5, 'A2', 'ブラック'),
('プレミアム黒帯', 'JitsuFlow限定デザインの黒帯。最高級の素材を使用。', 5000, 'belt', 20, 'A2', 'ブラック'),
('マウスガード', '柔術練習用のカスタムフィットマウスガード。', 2500, 'protector', 30, 'フリー', 'クリア'),
('膝サポーター（ペア）', '柔術専用設計の膝サポーター。左右セット。', 3800, 'protector', 15, 'M', 'ブラック'),
('JitsuFlow Tシャツ', 'JitsuFlowロゴ入りドライフィットTシャツ。', 3500, 'apparel', 25, 'L', 'ネイビー'),
('JitsuFlow ラッシュガード', '長袖ラッシュガード。UVカット機能付き。', 6800, 'apparel', 12, 'M', 'ブラック/グレー'),
('グラップリングダミー 30kg', '投げ技・寝技の練習用ダミー人形。', 45000, 'equipment', 3, '30kg', 'ブラック'),
('ヨガマット 6mm', '柔術のウォーミングアップに最適な厚手ヨガマット。', 4500, 'equipment', 20, '180x60cm', 'パープル');