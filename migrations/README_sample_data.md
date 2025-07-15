# Sample Data Migration Guide

This guide explains how to insert sample products and rentals data into your Cloudflare D1 database.

## Migration Files

1. **add_supplement_accessories_categories.sql** - Adds 'supplement' and 'accessories' categories to the products table
2. **insert_sample_products.sql** - Inserts all sample products from sampleProducts.js
3. **insert_sample_rentals.sql** - Inserts all sample rentals from sampleRentals.js

## Prerequisites

- Ensure you have dojos with IDs 1, 2, and 3 in your database
- If not, you'll need to insert dojos first or update the dojo_id values in the rentals migration

## Running the Migrations

Run the migrations in this order:

```bash
# 1. First, add the new product categories
wrangler d1 execute jitsuflow-db --file=./migrations/add_supplement_accessories_categories.sql

# 2. Insert sample products
wrangler d1 execute jitsuflow-db --file=./migrations/insert_sample_products.sql

# 3. Insert sample rentals
wrangler d1 execute jitsuflow-db --file=./migrations/insert_sample_rentals.sql
```

## What Gets Inserted

### Products (26 items total)
- **Gi (道着)**: 3 items - Premium gi in various colors and weights
- **Belts (帯)**: 5 items - White to black belts
- **Protectors**: 3 items - Mouth guards, ear guards, knee pads
- **Apparel**: 4 items - T-shirts, rashguards, fight shorts, compression wear
- **Equipment**: 3 items - Grappling dummy, mats, resistance bands
- **Supplements**: 3 items - Whey protein, BCAA, creatine
- **Accessories**: 3 items - Gi bag, finger tape, quick-dry towel

### Rentals (28 items total)
- **Dojo 1 (YAWARA)**: 19 items
  - Gi rentals (various sizes)
  - Belt rentals
  - Rashguards
  - Fight shorts
  - Protective gear
- **Dojo 2 (Over Limit Sapporo)**: 3 items
  - Gi rentals
- **Dojo 3 (スイープ道場)**: 5 items
  - Premium gi rentals
  - Navy rashguards

## Notes

- All products are set as active (is_active = 1)
- Stock quantities are set to realistic values
- Prices are in Japanese Yen (JPY)
- Product attributes are stored as JSON strings
- Rental items include deposit amounts and rental prices

## Verification

After running the migrations, you can verify the data was inserted correctly:

```sql
-- Check product count by category
SELECT category, COUNT(*) as count 
FROM products 
GROUP BY category;

-- Check rental count by dojo
SELECT dojo_id, COUNT(*) as count 
FROM rentals 
GROUP BY dojo_id;
```