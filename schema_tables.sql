-- JitsuFlow Database Schema
-- ブラジリアン柔術トレーニング＆道場予約システム

-- Users table
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  name TEXT NOT NULL,
  phone TEXT,
  stripe_customer_id TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Dojos table
CREATE TABLE dojos (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  address TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  website TEXT,
  description TEXT,
  max_capacity INTEGER DEFAULT 20,
  instructor TEXT,
  pricing_info TEXT,
  booking_system TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Class schedules table
CREATE TABLE class_schedules (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  dojo_id INTEGER NOT NULL,
  day_of_week INTEGER NOT NULL, -- 0=Sunday, 1=Monday, etc.
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  class_type TEXT NOT NULL,
  instructor TEXT,
  level TEXT, -- beginner, intermediate, advanced, all-levels
  is_active BOOLEAN DEFAULT TRUE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (dojo_id) REFERENCES dojos(id)
);

-- Bookings table
CREATE TABLE bookings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  dojo_id INTEGER NOT NULL,
  schedule_id INTEGER NOT NULL,
  booking_date DATE NOT NULL,
  status TEXT DEFAULT 'confirmed',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (dojo_id) REFERENCES dojos(id),
  FOREIGN KEY (schedule_id) REFERENCES class_schedules(id)
);

-- Instructors table
CREATE TABLE instructors (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  dojo_id INTEGER NOT NULL,
  belt_rank TEXT NOT NULL, -- black, brown, purple, blue, white
  birth_year INTEGER,
  bio TEXT,
  achievements TEXT, -- JSON array of achievements
  specialties TEXT, -- JSON array of specialties
  profile_image_url TEXT,
  is_head_instructor BOOLEAN DEFAULT FALSE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (dojo_id) REFERENCES dojos(id)
);

-- Videos table
CREATE TABLE videos (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  is_premium BOOLEAN DEFAULT FALSE,
  category TEXT,
  upload_url TEXT,
  file_size INTEGER,
  duration INTEGER,
  thumbnail_url TEXT,
  uploaded_by INTEGER,
  status TEXT DEFAULT 'pending', -- pending, published, unpublished
  views INTEGER DEFAULT 0,
  -- AI Analysis fields
  audio_transcript TEXT,
  detected_techniques TEXT, -- JSON array of detected techniques
  ai_confidence_score REAL,
  ai_generated_title TEXT,
  ai_generated_description TEXT,
  ai_suggested_category TEXT,
  -- Face Recognition fields
  detected_faces TEXT, -- JSON array of detected faces with positions
  face_recognition_data TEXT, -- JSON with face IDs and names
  deepfake_detection_score REAL,
  face_morph_applied BOOLEAN DEFAULT FALSE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (uploaded_by) REFERENCES users(id)
);

-- Teams table
CREATE TABLE teams (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  description TEXT,
  dojo_id INTEGER NOT NULL,
  created_by INTEGER NOT NULL,
  max_members INTEGER DEFAULT 50,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (dojo_id) REFERENCES dojos(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

-- Team memberships table
CREATE TABLE team_memberships (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  team_id INTEGER NOT NULL,
  role TEXT DEFAULT 'member', -- member, leader, admin
  status TEXT DEFAULT 'active', -- active, pending, inactive
  joined_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (team_id) REFERENCES teams(id),
  UNIQUE(user_id, team_id)
);

-- User dojo affiliations
CREATE TABLE user_dojo_affiliations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  dojo_id INTEGER NOT NULL,
  is_primary BOOLEAN DEFAULT FALSE,
  joined_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (dojo_id) REFERENCES dojos(id),
  UNIQUE(user_id, dojo_id)
);
