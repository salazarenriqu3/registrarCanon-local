-- =============================================================================
-- STORYBOARD DEMO PREP — run entire file in MySQL Workbench (or CLI)
-- Safe to re-run (idempotent where noted). Does NOT drop eacdb.
--
-- CLI from project root:
--   mysql -u root eacdb < registrar/db/demo_scripts/STORYBOARD_SQL_ALL_IN_ONE.sql
-- =============================================================================

USE eacdb;

SELECT '=== SCENE 0.1 — Active term check ===' AS storyboard_scene;
SELECT term_id, term_code, term_name, is_active, status
FROM academic_terms WHERE is_active = 1;
SELECT setting_key, setting_value FROM system_settings
WHERE setting_key = 'CURRENT_ACADEMIC_TERM';

-- ── SCENE 0.2 — Sprint schema (skip if fresh bootstrap already ran step 18) ─
-- Full file: registrar/db/migrations/20260619_sprint_1_10_upgrade.sql
SELECT '=== SCENE 0.2 — Sprint tables present ===' AS storyboard_scene;
SELECT table_name FROM information_schema.tables
WHERE table_schema = DATABASE()
  AND table_name IN (
    'grading_schemes', 'student_holds', 'student_program_shift_requests'
  )
ORDER BY table_name;

-- ── SCENE 0.3 — Enrollment period dates (Act 9 demo) ───────────────────────
SELECT '=== SCENE 0.3 — Enrollment period settings ===' AS storyboard_scene;

UPDATE system_settings SET setting_value = '2026-01-01'
WHERE setting_key = 'ENROLLMENT_OPEN_DATE';
UPDATE system_settings SET setting_value = '2026-12-31'
WHERE setting_key = 'ENROLLMENT_CLOSE_DATE';
UPDATE system_settings SET setting_value = '2026-08-15'
WHERE setting_key = 'ADD_DROP_CLOSE_DATE';
UPDATE system_settings SET setting_value = 'false'
WHERE setting_key = 'LATE_ENROLLMENT_FEE_ENABLED';

INSERT INTO system_settings (setting_key, setting_value)
SELECT k, v FROM (
    SELECT 'ENROLLMENT_OPEN_DATE' AS k, '2026-01-01' AS v UNION ALL
    SELECT 'ENROLLMENT_CLOSE_DATE', '2026-12-31' UNION ALL
    SELECT 'ADD_DROP_CLOSE_DATE', '2026-08-15' UNION ALL
    SELECT 'LATE_ENROLLMENT_FEE_ENABLED', 'false'
) seeds
WHERE NOT EXISTS (SELECT 1 FROM system_settings s WHERE s.setting_key = seeds.k);

SELECT setting_key, setting_value FROM system_settings
WHERE setting_key IN (
  'ENROLLMENT_OPEN_DATE', 'ENROLLMENT_CLOSE_DATE',
  'ADD_DROP_CLOSE_DATE', 'LATE_ENROLLMENT_FEE_ENABLED'
)
ORDER BY setting_key;

-- ── SCENE 0.4 — Midterm policy (Act 5 withdrawal deadline) ────────────────
SELECT '=== SCENE 0.4 — Midterm exam date (active term) ===' AS storyboard_scene;

INSERT INTO academic_term_policies (term_id, midterm_exam_date)
SELECT t.term_id, DATE_ADD(CURDATE(), INTERVAL 60 DAY)
FROM academic_terms t WHERE t.is_active = 1
ON DUPLICATE KEY UPDATE midterm_exam_date = VALUES(midterm_exam_date);

SELECT t.term_code, p.midterm_exam_date
FROM academic_terms t
LEFT JOIN academic_term_policies p ON p.term_id = t.term_id
WHERE t.is_active = 1;

-- ── SCENE 0.5 — Demo student + holds (Act 7) ──────────────────────────────
SELECT '=== SCENE 0.5 — Sprint demo student + OSA hold ===' AS storyboard_scene;

SET @demo_sn := 'SPRINT-DEMO-2026-001';

INSERT INTO students (
    student_number, reference_number, real_name, program_code,
    year_level, semester, enrollment_status_type, student_type
)
SELECT @demo_sn, 'SPRINT-DEMO-REF-001', 'Sprint Demo Student', 'BSCPE', 1, 1, 'ENROLLED', 'REGULAR'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM students WHERE student_number = @demo_sn);

DELETE FROM student_holds
WHERE student_number = @demo_sn AND office = 'OSA' AND reason LIKE 'Demo hold%';

INSERT INTO student_holds (student_number, office, reason, active, created_by)
VALUES (@demo_sn, 'OSA', 'Demo hold — unreturned student ID (clear in Student Manager)', 1, 'storyboard');

SELECT hold_id, student_number, office, active, LEFT(reason, 60) AS reason
FROM student_holds WHERE student_number = @demo_sn;

-- ── SCENE 0.6 — Course types sample (Act 2) ───────────────────────────────
SELECT '=== SCENE 0.6 — Course types ===' AS storyboard_scene;

UPDATE courses SET course_type = 'TUTORIAL'
WHERE course_code IN ('GE1', 'GE 1') AND COALESCE(course_type, 'REGULAR') = 'REGULAR';

SELECT course_code, course_type FROM courses
WHERE course_type <> 'REGULAR' LIMIT 5;

-- ── SCENE 0.7 — Grading scheme default (Act 6) ────────────────────────────
SELECT '=== SCENE 0.7 — Default grading scheme ===' AS storyboard_scene;

INSERT INTO grading_schemes (program_code, class_standing_percent, exam_percent, base_scale)
SELECT NULL, 50.00, 50.00, 'POINT' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM grading_schemes WHERE program_code IS NULL);

SELECT scheme_id, program_code, class_standing_percent, exam_percent, base_scale
FROM grading_schemes WHERE program_code IS NULL;

-- ── SCENE 0.8 — Withdrawal penalty tier (Act 5) ───────────────────────────
SELECT '=== SCENE 0.8 — Withdrawal penalty setting ===' AS storyboard_scene;

INSERT INTO enrollment_settings (setting_key, setting_value, description)
SELECT 'drop_penalty_first_week_percent', '25', 'First-two-weeks withdrawal charge percent'
FROM DUAL
WHERE NOT EXISTS (
  SELECT 1 FROM enrollment_settings WHERE setting_key = 'drop_penalty_first_week_percent'
);

SELECT setting_key, setting_value FROM enrollment_settings
WHERE setting_key = 'drop_penalty_first_week_percent';

-- ── SCENE 0.9 — Readiness summary ─────────────────────────────────────────
SELECT '=== SCENE 0.9 — Demo readiness summary ===' AS storyboard_scene;

SELECT 'grading_schemes' AS obj,
  IF(COUNT(*)>0,'OK','MISSING') AS status
FROM information_schema.tables
WHERE table_schema=DATABASE() AND table_name='grading_schemes'
UNION ALL
SELECT 'student_holds',
  IF(COUNT(*)>0,'OK','MISSING')
FROM information_schema.tables
WHERE table_schema=DATABASE() AND table_name='student_holds'
UNION ALL
SELECT 'demo_student',
  IF(COUNT(*)>0,'OK','MISSING')
FROM students WHERE student_number='SPRINT-DEMO-2026-001';

SELECT 'STORYBOARD_PREP' AS status, 'COMPLETE' AS result, NOW() AS completed_at;

-- ── OPTIONAL Act 5 — Full withdrawal UAT student ──────────────────────────
-- Uncomment next line OR run separately:
-- SOURCE registrar/db/demo_scripts/16_withdrawal_uat_seed.sql;
