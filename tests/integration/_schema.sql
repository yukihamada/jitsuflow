-- Minimal D1 schema for integration tests.
-- Add tables here as new tests need them. Mirrors production columns
-- actually referenced by the API layer (production migrations may
-- include additional historical columns we don't exercise in tests).

CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  name TEXT NOT NULL,
  phone TEXT,
  role TEXT DEFAULT 'user',
  is_active INTEGER DEFAULT 1,
  stripe_customer_id TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
