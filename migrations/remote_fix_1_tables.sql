-- Create revenue sharing tables
CREATE TABLE IF NOT EXISTS dojo_revenue_settings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    dojo_id INTEGER NOT NULL,
    default_instructor_rate INTEGER DEFAULT 70,
    default_dojo_rate INTEGER DEFAULT 30,
    default_usage_fee INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (dojo_id) REFERENCES dojos(id),
    UNIQUE(dojo_id)
);

CREATE TABLE IF NOT EXISTS instructor_revenue_settings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    instructor_id INTEGER NOT NULL,
    dojo_id INTEGER NOT NULL,
    custom_instructor_rate INTEGER,
    custom_dojo_rate INTEGER,
    custom_usage_fee INTEGER,
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (instructor_id) REFERENCES instructors(id),
    FOREIGN KEY (dojo_id) REFERENCES dojos(id),
    UNIQUE(instructor_id, dojo_id)
);