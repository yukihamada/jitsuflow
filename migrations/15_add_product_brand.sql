-- Add brand column to products table
ALTER TABLE products ADD COLUMN brand TEXT;

-- Update brand based on product names
UPDATE products SET brand = 'SWEEP' WHERE name LIKE '%SWEEP%' OR name LIKE '%SIIIEEP%';
UPDATE products SET brand = 'YAWARA' WHERE name LIKE '%YAWARA%' OR name LIKE '%ヤワラ%';

-- Set default brand for products without explicit brand
UPDATE products SET brand = 
  CASE 
    WHEN id <= 46 AND brand IS NULL THEN 'SWEEP'
    WHEN id > 46 AND brand IS NULL THEN 'YAWARA'
    ELSE brand
  END;