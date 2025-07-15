-- Add soft delete column to users table only (products already has it)

-- Add is_active to users
ALTER TABLE users ADD COLUMN is_active INTEGER DEFAULT 1;