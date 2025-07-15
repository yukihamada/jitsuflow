-- Add role column to users table

-- Add role column with default value 'student'
ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'student';

-- Update existing admin user
UPDATE users SET role = 'admin' WHERE email = 'admin@jitsuflow.app';