-- 予約システム強化用テーブル
-- JitsuFlow Enhancement: Advanced Booking System

-- クラス定員管理テーブル
CREATE TABLE class_capacity (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  schedule_id INTEGER NOT NULL,
  max_capacity INTEGER NOT NULL DEFAULT 20,
  current_bookings INTEGER NOT NULL DEFAULT 0,
  allow_waitlist BOOLEAN DEFAULT TRUE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (schedule_id) REFERENCES class_schedules(id),
  UNIQUE(schedule_id)
);

-- キャンセル待ちリストテーブル
CREATE TABLE booking_waitlists (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  schedule_id INTEGER NOT NULL,
  booking_date DATE NOT NULL,
  position INTEGER NOT NULL,
  status TEXT DEFAULT 'waiting', -- waiting, confirmed, cancelled, expired
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  notified_at DATETIME,
  expires_at DATETIME,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (schedule_id) REFERENCES class_schedules(id),
  UNIQUE(user_id, schedule_id, booking_date)
);

-- 通知履歴テーブル
CREATE TABLE notifications (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  type TEXT NOT NULL, -- booking_confirmed, waitlist_available, payment_due, class_reminder
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  data TEXT, -- JSON形式の追加データ
  status TEXT DEFAULT 'pending', -- pending, sent, failed, read
  channel TEXT DEFAULT 'app', -- app, email, sms, push
  sent_at DATETIME,
  read_at DATETIME,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- 出席記録テーブル
CREATE TABLE class_attendance (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  booking_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  schedule_id INTEGER NOT NULL,
  attendance_date DATE NOT NULL,
  status TEXT DEFAULT 'absent', -- present, absent, late, early_leave
  checked_in_at DATETIME,
  checked_out_at DATETIME,
  notes TEXT,
  instructor_notes TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (booking_id) REFERENCES bookings(id),
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (schedule_id) REFERENCES class_schedules(id),
  UNIQUE(booking_id)
);

-- インストラクターレポートテーブル
CREATE TABLE instructor_reports (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  instructor_id INTEGER NOT NULL,
  schedule_id INTEGER NOT NULL,
  report_date DATE NOT NULL,
  total_students INTEGER DEFAULT 0,
  attendance_rate REAL DEFAULT 0,
  class_rating REAL, -- インストラクター自己評価 1-5
  student_feedback_avg REAL, -- 生徒評価平均
  techniques_taught TEXT, -- JSON配列
  focus_areas TEXT, -- JSON配列
  notes TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (instructor_id) REFERENCES users(id),
  FOREIGN KEY (schedule_id) REFERENCES class_schedules(id)
);

-- 生徒進捗記録テーブル
CREATE TABLE student_progress (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  instructor_id INTEGER NOT NULL,
  technique_name TEXT NOT NULL,
  proficiency_level INTEGER DEFAULT 1, -- 1-5スケール
  last_practiced DATE,
  notes TEXT,
  video_reference TEXT, -- 参考動画URL
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (instructor_id) REFERENCES users(id)
);

-- bookingsテーブル拡張（既存テーブルにカラム追加）
ALTER TABLE bookings ADD COLUMN attendance_status TEXT DEFAULT 'pending'; -- pending, present, absent, cancelled
ALTER TABLE bookings ADD COLUMN checked_in_at DATETIME;
ALTER TABLE bookings ADD COLUMN checked_out_at DATETIME;
ALTER TABLE bookings ADD COLUMN reminder_sent BOOLEAN DEFAULT FALSE;
ALTER TABLE bookings ADD COLUMN is_from_waitlist BOOLEAN DEFAULT FALSE;

-- class_schedulesテーブル拡張
ALTER TABLE class_schedules ADD COLUMN max_capacity INTEGER DEFAULT 20;
ALTER TABLE class_schedules ADD COLUMN current_bookings INTEGER DEFAULT 0;
ALTER TABLE class_schedules ADD COLUMN allow_waitlist BOOLEAN DEFAULT TRUE;
ALTER TABLE class_schedules ADD COLUMN reminder_hours INTEGER DEFAULT 24; -- 何時間前にリマインダー送信

-- paymentsテーブル拡張（レンタル・POS対応）
ALTER TABLE payments ADD COLUMN pos_transaction_id TEXT;
ALTER TABLE payments ADD COLUMN receipt_data TEXT; -- JSON形式のレシートデータ
ALTER TABLE payments ADD COLUMN refund_amount INTEGER DEFAULT 0;
ALTER TABLE payments ADD COLUMN refund_reason TEXT;
ALTER TABLE payments ADD COLUMN cashier_id INTEGER REFERENCES users(id);

-- 自動的にclass_capacityレコードを作成するトリガー
CREATE TRIGGER create_class_capacity_trigger 
  AFTER INSERT ON class_schedules
BEGIN
  INSERT INTO class_capacity (schedule_id, max_capacity, current_bookings)
  VALUES (NEW.id, COALESCE(NEW.max_capacity, 20), 0);
END;

-- 予約作成時にcurrent_bookings更新トリガー
CREATE TRIGGER update_booking_count_insert_trigger
  AFTER INSERT ON bookings
  WHEN NEW.status = 'confirmed'
BEGIN
  UPDATE class_capacity 
  SET current_bookings = current_bookings + 1,
      updated_at = CURRENT_TIMESTAMP
  WHERE schedule_id = NEW.schedule_id;
  
  UPDATE class_schedules 
  SET current_bookings = current_bookings + 1,
      updated_at = CURRENT_TIMESTAMP
  WHERE id = NEW.schedule_id;
END;

-- 予約キャンセル時にcurrent_bookings更新トリガー
CREATE TRIGGER update_booking_count_cancel_trigger
  AFTER UPDATE ON bookings
  WHEN OLD.status = 'confirmed' AND NEW.status = 'cancelled'
BEGIN
  UPDATE class_capacity 
  SET current_bookings = current_bookings - 1,
      updated_at = CURRENT_TIMESTAMP
  WHERE schedule_id = NEW.schedule_id;
  
  UPDATE class_schedules 
  SET current_bookings = current_bookings - 1,
      updated_at = CURRENT_TIMESTAMP
  WHERE id = NEW.schedule_id;
  
  -- キャンセル待ちリストから次の人を自動確認
  UPDATE booking_waitlists 
  SET status = 'confirmed',
      updated_at = CURRENT_TIMESTAMP,
      expires_at = datetime('now', '+2 hours')
  WHERE schedule_id = NEW.schedule_id 
    AND booking_date = NEW.booking_date
    AND status = 'waiting'
    AND position = (
      SELECT MIN(position) 
      FROM booking_waitlists 
      WHERE schedule_id = NEW.schedule_id 
        AND booking_date = NEW.booking_date 
        AND status = 'waiting'
    );
END;

-- インデックス追加
CREATE INDEX idx_booking_waitlists_schedule_date ON booking_waitlists(schedule_id, booking_date);
CREATE INDEX idx_booking_waitlists_status ON booking_waitlists(status);
CREATE INDEX idx_notifications_user_status ON notifications(user_id, status);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_class_attendance_date ON class_attendance(attendance_date);
CREATE INDEX idx_instructor_reports_instructor_date ON instructor_reports(instructor_id, report_date);
CREATE INDEX idx_student_progress_user ON student_progress(user_id);
CREATE INDEX idx_class_capacity_schedule ON class_capacity(schedule_id);

-- サンプルデータ挿入
INSERT INTO class_capacity (schedule_id, max_capacity, current_bookings)
SELECT id, COALESCE(max_capacity, 20), COALESCE(current_bookings, 0)
FROM class_schedules
WHERE id NOT IN (SELECT schedule_id FROM class_capacity);

-- 既存予約の出席記録初期化
INSERT INTO class_attendance (booking_id, user_id, schedule_id, attendance_date, status)
SELECT 
  b.id,
  b.user_id,
  b.schedule_id,
  b.booking_date,
  'absent'
FROM bookings b
WHERE b.status = 'confirmed' 
  AND b.booking_date < DATE('now')
  AND b.id NOT IN (SELECT booking_id FROM class_attendance WHERE booking_id IS NOT NULL);