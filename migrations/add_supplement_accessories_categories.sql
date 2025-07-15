-- Add supplement and accessories categories to products table
-- This migration extends the product categories to include 'supplement' and 'accessories'

-- Create new products table with updated categories including supplement and accessories
CREATE TABLE IF NOT EXISTS products_new (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  description TEXT,
  price REAL NOT NULL,
  category TEXT NOT NULL CHECK (category IN (
    'gi', 'belt', 'protector', 'apparel', 'equipment',
    'training', 'healing', 'bjj_training', 'rental', 'trial', 'other',
    'supplement', 'accessories'
  )),
  image_url TEXT,
  stock_quantity INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1,
  size TEXT,
  color TEXT,
  attributes TEXT, -- JSON string for additional attributes
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Copy existing data
INSERT INTO products_new SELECT * FROM products;

-- Drop old table and rename new one
DROP TABLE products;
ALTER TABLE products_new RENAME TO products;

-- Recreate indexes
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_active ON products(is_active);

-- Recreate triggers
CREATE TRIGGER update_products_timestamp 
AFTER UPDATE ON products
BEGIN
  UPDATE products SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

-- Now update the products that were inserted as 'other' but should be 'supplement' or 'accessories'
UPDATE products 
SET category = 'supplement' 
WHERE category = 'other' 
  AND attributes LIKE '%"type":"supplement"%' 
  OR attributes LIKE '%"category":"supplement"%';

UPDATE products 
SET category = 'accessories' 
WHERE category = 'other' 
  AND attributes LIKE '%"type":"accessories"%';