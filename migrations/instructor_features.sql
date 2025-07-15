-- インストラクター機能強化テーブル
-- JitsuFlow Enhancement: Advanced Instructor Features

-- インストラクタースケジュール管理テーブル
CREATE TABLE instructor_schedules (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  instructor_id INTEGER NOT NULL,
  schedule_id INTEGER NOT NULL,
  role TEXT DEFAULT 'main', -- main, assistant, substitute
  confirmed BOOLEAN DEFAULT FALSE,
  substitute_for INTEGER, -- 代理の場合の元インストラクターID
  notes TEXT,
  preparation_time INTEGER DEFAULT 30, -- 準備時間（分）
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (instructor_id) REFERENCES users(id),
  FOREIGN KEY (schedule_id) REFERENCES class_schedules(id),
  FOREIGN KEY (substitute_for) REFERENCES users(id)
);

-- インストラクター可用性テーブル
CREATE TABLE instructor_availability (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  instructor_id INTEGER NOT NULL,
  day_of_week INTEGER NOT NULL, -- 0=Sunday, 1=Monday, etc.
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  status TEXT DEFAULT 'available', -- available, busy, preferred, unavailable
  recurring BOOLEAN DEFAULT TRUE,
  effective_date DATE,
  end_date DATE,
  notes TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (instructor_id) REFERENCES users(id)
);

-- インストラクター休暇・不在テーブル
CREATE TABLE instructor_absences (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  instructor_id INTEGER NOT NULL,
  absence_type TEXT NOT NULL, -- vacation, sick, personal, training
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  status TEXT DEFAULT 'pending', -- pending, approved, rejected
  reason TEXT,
  substitute_instructor_id INTEGER,
  approved_by INTEGER,
  approved_at DATETIME,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (instructor_id) REFERENCES users(id),
  FOREIGN KEY (substitute_instructor_id) REFERENCES users(id),
  FOREIGN KEY (approved_by) REFERENCES users(id)
);

-- インストラクター評価テーブル
CREATE TABLE instructor_ratings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  instructor_id INTEGER NOT NULL,
  student_id INTEGER NOT NULL,
  schedule_id INTEGER NOT NULL,
  class_date DATE NOT NULL,
  overall_rating INTEGER NOT NULL, -- 1-5
  teaching_clarity INTEGER, -- 1-5
  technique_demonstration INTEGER, -- 1-5
  individual_attention INTEGER, -- 1-5
  class_organization INTEGER, -- 1-5
  feedback TEXT,
  anonymous BOOLEAN DEFAULT FALSE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (instructor_id) REFERENCES users(id),
  FOREIGN KEY (student_id) REFERENCES users(id),
  FOREIGN KEY (schedule_id) REFERENCES class_schedules(id)
);

-- インストラクター目標・KPIテーブル
CREATE TABLE instructor_goals (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  instructor_id INTEGER NOT NULL,
  goal_type TEXT NOT NULL, -- attendance_rate, student_retention, revenue, certification
  target_value REAL NOT NULL,
  current_value REAL DEFAULT 0,
  measurement_period TEXT DEFAULT 'monthly', -- weekly, monthly, quarterly, yearly
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  status TEXT DEFAULT 'active', -- active, completed, paused, cancelled
  description TEXT,
  reward TEXT, -- 達成時の報酬
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (instructor_id) REFERENCES users(id)
);

-- インストラクター認定・資格テーブル
CREATE TABLE instructor_certifications (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  instructor_id INTEGER NOT NULL,
  certification_name TEXT NOT NULL,
  issuing_organization TEXT NOT NULL,
  certification_date DATE NOT NULL,
  expiry_date DATE,
  certificate_number TEXT,
  certificate_url TEXT,
  status TEXT DEFAULT 'active', -- active, expired, revoked
  notes TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (instructor_id) REFERENCES users(id)
);

-- インストラクター給与明細拡張テーブル
CREATE TABLE instructor_payroll_details (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  payroll_id INTEGER NOT NULL,
  item_type TEXT NOT NULL, -- base_salary, class_fee, bonus, deduction, expense
  description TEXT NOT NULL,
  quantity REAL DEFAULT 1,
  rate REAL NOT NULL,
  amount INTEGER NOT NULL,
  taxable BOOLEAN DEFAULT TRUE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (payroll_id) REFERENCES instructor_payrolls(id)
);

-- 生徒-インストラクター関係テーブル
CREATE TABLE student_instructor_relationships (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  student_id INTEGER NOT NULL,
  instructor_id INTEGER NOT NULL,
  relationship_type TEXT DEFAULT 'student', -- student, private_student, mentee
  start_date DATE NOT NULL,
  end_date DATE,
  status TEXT DEFAULT 'active', -- active, inactive, graduated
  primary_instructor BOOLEAN DEFAULT FALSE,
  notes TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (student_id) REFERENCES users(id),
  FOREIGN KEY (instructor_id) REFERENCES users(id),
  UNIQUE(student_id, instructor_id, relationship_type)
);

-- インストラクター通知設定テーブル
CREATE TABLE instructor_notification_settings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  instructor_id INTEGER NOT NULL,
  notification_type TEXT NOT NULL, -- class_reminder, schedule_change, payroll, rating
  enabled BOOLEAN DEFAULT TRUE,
  email_enabled BOOLEAN DEFAULT TRUE,
  sms_enabled BOOLEAN DEFAULT FALSE,
  push_enabled BOOLEAN DEFAULT TRUE,
  advance_hours INTEGER DEFAULT 24,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (instructor_id) REFERENCES users(id),
  UNIQUE(instructor_id, notification_type)
);

-- インストラクター実績ビュー（月間）
CREATE VIEW instructor_monthly_stats AS
SELECT 
  i.instructor_id,
  u.name as instructor_name,
  DATE(ir.report_date, 'start of month') as month,
  COUNT(DISTINCT ir.id) as classes_taught,
  SUM(ir.total_students) as total_students_taught,
  AVG(ir.attendance_rate) as avg_attendance_rate,
  AVG(ir.class_rating) as avg_self_rating,
  AVG(rat.overall_rating) as avg_student_rating,
  SUM(ipd.amount) as total_earnings
FROM instructor_dojo_assignments i
JOIN users u ON i.instructor_id = u.id
LEFT JOIN instructor_reports ir ON i.instructor_id = ir.instructor_id
LEFT JOIN instructor_ratings rat ON i.instructor_id = rat.instructor_id 
  AND DATE(rat.class_date, 'start of month') = DATE(ir.report_date, 'start of month')
LEFT JOIN instructor_payrolls ip ON i.instructor_id = ip.instructor_id
  AND DATE(ip.period_start, 'start of month') = DATE(ir.report_date, 'start of month')
LEFT JOIN instructor_payroll_details ipd ON ip.id = ipd.payroll_id
WHERE i.status = 'active'
GROUP BY i.instructor_id, DATE(ir.report_date, 'start of month');

-- usersテーブル拡張（インストラクター向け）
ALTER TABLE users ADD COLUMN instructor_bio TEXT;
ALTER TABLE users ADD COLUMN instructor_specialties TEXT; -- JSON配列
ALTER TABLE users ADD COLUMN instructor_availability_notes TEXT;
ALTER TABLE users ADD COLUMN preferred_class_size INTEGER DEFAULT 15;
ALTER TABLE users ADD COLUMN hourly_rate INTEGER; -- 時給（円）
ALTER TABLE users ADD COLUMN commission_rate REAL; -- 歩合率（%）

-- class_schedulesテーブル拡張（インストラクター管理用）
ALTER TABLE class_schedules ADD COLUMN assistant_instructor TEXT;
ALTER TABLE class_schedules ADD COLUMN min_students INTEGER DEFAULT 3;
ALTER TABLE class_schedules ADD COLUMN preparation_notes TEXT;
ALTER TABLE class_schedules ADD COLUMN equipment_needed TEXT; -- JSON配列

-- インデックス追加
CREATE INDEX idx_instructor_schedules_instructor ON instructor_schedules(instructor_id);
CREATE INDEX idx_instructor_schedules_schedule ON instructor_schedules(schedule_id);
CREATE INDEX idx_instructor_availability_instructor_day ON instructor_availability(instructor_id, day_of_week);
CREATE INDEX idx_instructor_absences_instructor_dates ON instructor_absences(instructor_id, start_date, end_date);
CREATE INDEX idx_instructor_ratings_instructor ON instructor_ratings(instructor_id);
CREATE INDEX idx_instructor_ratings_date ON instructor_ratings(class_date);
CREATE INDEX idx_instructor_goals_instructor_status ON instructor_goals(instructor_id, status);
CREATE INDEX idx_instructor_certifications_instructor ON instructor_certifications(instructor_id);
CREATE INDEX idx_student_instructor_relationships_student ON student_instructor_relationships(student_id);
CREATE INDEX idx_student_instructor_relationships_instructor ON student_instructor_relationships(instructor_id);

-- デフォルトの通知設定を作成するトリガー
CREATE TRIGGER create_instructor_notification_settings_trigger
  AFTER UPDATE ON users
  WHEN NEW.role = 'instructor' AND (OLD.role != 'instructor' OR OLD.role IS NULL)
BEGIN
  INSERT OR IGNORE INTO instructor_notification_settings (instructor_id, notification_type)
  VALUES 
    (NEW.id, 'class_reminder'),
    (NEW.id, 'schedule_change'),
    (NEW.id, 'payroll'),
    (NEW.id, 'rating');
END;

-- 既存インストラクターの通知設定初期化
INSERT OR IGNORE INTO instructor_notification_settings (instructor_id, notification_type)
SELECT u.id, setting.notification_type
FROM users u
CROSS JOIN (
  SELECT 'class_reminder' as notification_type
  UNION SELECT 'schedule_change'
  UNION SELECT 'payroll'
  UNION SELECT 'rating'
) setting
WHERE u.role = 'instructor';

-- 既存クラススケジュールにインストラクタースケジュール作成
INSERT INTO instructor_schedules (instructor_id, schedule_id, role, confirmed)
SELECT 
  u.id as instructor_id,
  s.id as schedule_id,
  'main' as role,
  TRUE as confirmed
FROM class_schedules s
JOIN users u ON s.instructor = u.name
WHERE u.role = 'instructor'
  AND NOT EXISTS (
    SELECT 1 FROM instructor_schedules is2 
    WHERE is2.instructor_id = u.id AND is2.schedule_id = s.id
  );