-- 生徒の担当インストラクター設定テーブル
CREATE TABLE IF NOT EXISTS student_instructor_assignments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  student_id INTEGER NOT NULL,
  instructor_id INTEGER NOT NULL,
  dojo_id INTEGER NOT NULL,
  assignment_type TEXT NOT NULL DEFAULT 'primary', -- primary, secondary
  status TEXT NOT NULL DEFAULT 'active', -- active, inactive
  start_date TEXT NOT NULL,
  end_date TEXT,
  notes TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (instructor_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (dojo_id) REFERENCES dojos(id) ON DELETE CASCADE,
  
  -- 同じ道場で同じタイプの担当は1人まで
  UNIQUE(student_id, dojo_id, assignment_type, status)
);

-- インデックス作成
CREATE INDEX idx_student_instructor_student ON student_instructor_assignments(student_id);
CREATE INDEX idx_student_instructor_instructor ON student_instructor_assignments(instructor_id);
CREATE INDEX idx_student_instructor_dojo ON student_instructor_assignments(dojo_id);

-- 生徒の学習進捗記録テーブル
CREATE TABLE IF NOT EXISTS student_progress_records (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  student_id INTEGER NOT NULL,
  instructor_id INTEGER NOT NULL,
  technique_category TEXT NOT NULL,
  technique_name TEXT NOT NULL,
  proficiency_level INTEGER NOT NULL DEFAULT 1, -- 1-5
  notes TEXT,
  recorded_date TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (instructor_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 動画管理用の拡張
ALTER TABLE videos ADD COLUMN file_url TEXT;
ALTER TABLE videos ADD COLUMN file_size INTEGER;
ALTER TABLE videos ADD COLUMN mime_type TEXT;
ALTER TABLE videos ADD COLUMN cloudflare_id TEXT;
ALTER TABLE videos ADD COLUMN processing_status TEXT DEFAULT 'pending';
ALTER TABLE videos ADD COLUMN uploaded_by INTEGER REFERENCES users(id);

-- 動画アクセス権限テーブル
CREATE TABLE IF NOT EXISTS video_access_permissions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  video_id INTEGER NOT NULL,
  permission_type TEXT NOT NULL, -- 'public', 'members_only', 'specific_students', 'specific_dojos'
  permission_value TEXT, -- JSON配列でユーザーIDや道場IDを格納
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (video_id) REFERENCES videos(id) ON DELETE CASCADE
);

-- 生徒のお気に入りインストラクター
CREATE TABLE IF NOT EXISTS favorite_instructors (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  student_id INTEGER NOT NULL,
  instructor_id INTEGER NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (instructor_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE(student_id, instructor_id)
);