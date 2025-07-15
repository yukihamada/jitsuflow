-- Assign instructors to their dojos
INSERT INTO instructor_dojos (instructor_id, dojo_id, role, start_date, is_active) VALUES
-- YAWARA東京のインストラクター
(1, 1, 'head_instructor', '2015-01-01', 1),
(2, 1, 'instructor', '2018-04-01', 1),
(3, 1, 'instructor', '2019-06-01', 1),
(4, 1, 'instructor', '2020-03-01', 1),
(5, 1, 'instructor', '2016-09-01', 1),
(6, 1, 'instructor', '2021-01-01', 1),
(7, 1, 'head_instructor', '2010-05-01', 1),
(8, 1, 'instructor', '2018-07-01', 1),
(9, 1, 'instructor', '2019-11-01', 1),
(10, 1, 'instructor', '2022-02-01', 1),
(11, 1, 'instructor', '2022-06-01', 1),
(12, 1, 'instructor', '2018-01-01', 1),
(13, 1, 'instructor', '2020-08-01', 1),
-- SWEEP東京のインストラクター
(14, 2, 'head_instructor', '2017-09-01', 1),
(15, 2, 'instructor', '2019-04-01', 1),
(16, 2, 'instructor', '2020-06-01', 1),
-- OverLimit札幌のインストラクター
(17, 3, 'head_instructor', '2015-03-01', 1);

-- Add custom revenue settings for premium instructors
INSERT INTO instructor_revenue_settings (instructor_id, dojo_id, custom_instructor_rate, custom_dojo_rate, custom_usage_fee, notes) VALUES
(1, 1, 80, 20, 2000, '一木トレーナー特別レート'),
(7, 1, 85, 15, 1500, '村田トレーナー特別レート');