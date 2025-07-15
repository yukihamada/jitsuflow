-- レンタル管理テーブル
CREATE TABLE rentals (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  -- アイテム情報
  item_type TEXT NOT NULL, -- gi, belt, protector, other
  item_name TEXT NOT NULL,
  size TEXT,
  color TEXT,
  condition TEXT DEFAULT 'good', -- new, good, fair, poor
  -- 在庫管理
  dojo_id INTEGER NOT NULL,
  total_quantity INTEGER NOT NULL DEFAULT 1,
  available_quantity INTEGER NOT NULL DEFAULT 1,
  -- 料金
  rental_price INTEGER NOT NULL, -- 1回あたりの料金（円）
  deposit_amount INTEGER DEFAULT 0, -- デポジット額
  -- ステータス
  status TEXT DEFAULT 'available', -- available, maintenance, retired
  -- メタデータ
  barcode TEXT UNIQUE,
  notes TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (dojo_id) REFERENCES dojos(id)
);

-- レンタル履歴テーブル
CREATE TABLE rental_transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  rental_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  -- レンタル情報
  rental_date DATETIME NOT NULL,
  return_due_date DATETIME NOT NULL,
  actual_return_date DATETIME,
  -- 料金
  rental_fee INTEGER NOT NULL,
  deposit_paid INTEGER DEFAULT 0,
  late_fee INTEGER DEFAULT 0,
  damage_fee INTEGER DEFAULT 0,
  total_paid INTEGER NOT NULL,
  -- ステータス
  status TEXT DEFAULT 'active', -- active, returned, overdue, lost
  condition_on_return TEXT, -- good, damaged, lost
  -- 支払い
  payment_id INTEGER REFERENCES payments(id),
  -- メタデータ
  notes TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (rental_id) REFERENCES rentals(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- インデックス追加
CREATE INDEX idx_rentals_dojo ON rentals(dojo_id);
CREATE INDEX idx_rental_transactions_status ON rental_transactions(status);