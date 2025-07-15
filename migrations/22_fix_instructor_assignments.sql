-- Re-add 佐藤健 to OverLimit札幌 (he should be at both YAWARA and OverLimit)
INSERT OR IGNORE INTO instructor_dojos (instructor_id, dojo_id, role, start_date, is_active) VALUES
(3, 3, 'instructor', '2023-01-01', 1);

-- Re-add 北野武 to OverLimit札幌 as regular instructor
INSERT OR IGNORE INTO instructor_dojos (instructor_id, dojo_id, role, start_date, is_active) VALUES
(4, 3, 'instructor', '2020-06-01', 1);