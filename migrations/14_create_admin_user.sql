-- Create admin user if not exists
INSERT OR IGNORE INTO users (email, password_hash, name, role, is_active, created_at, updated_at)
VALUES (
  'admin@jitsuflow.app',
  'YWRtaW4xMjM=', -- base64 encoded 'admin123'
  'Admin User',
  'admin',
  1,
  datetime('now'),
  datetime('now')
);