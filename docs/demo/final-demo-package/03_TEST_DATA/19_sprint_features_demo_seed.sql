-- =============================================================================
-- Sprint 1–10 demo / UAT seed (idempotent)
--
-- Purpose: populate Finance Policy dates, sample holds, course types, and
-- midterm exam policy so evaluators can demo sprint features without manual UI.
--
-- Safe to re-run. Does NOT drop data.
--
-- Apply after fresh bootstrap or migration upgrade:
--   mysql -u root eacdb < registrar/db/demo_scripts/19_sprint_features_demo_seed.sql
--
-- Demo paths (admin / 1234):
--   /admin/finance-policy          — enrollment dates pre-filled
--   /admin/slot-monitoring         — slot dashboard
--   /admin/programs                — program builder
--   /admin/student-manager?username=SPRINT-DEMO-2026-001 — holds UI
--   /faculty/program-shifts        — program shift queue
--   /dean/student-evaluation?studentNumber=SPRINT-DEMO-2026-001
-- =============================================================================

USE eacdb;

-- ── Enrollment period dates (active term window) ────────────────────────────
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

-- ── Midterm exam date for active term (withdrawal deadline demo) ────────────
INSERT INTO academic_term_policies (term_id, midterm_exam_date)
SELECT t.term_id, DATE_ADD(CURDATE(), INTERVAL 60 DAY)
FROM academic_terms t
WHERE t.is_active = 1
ON DUPLICATE KEY UPDATE midterm_exam_date = VALUES(midterm_exam_date);

-- ── Sample course types ─────────────────────────────────────────────────────
UPDATE courses SET course_type = 'TUTORIAL'
WHERE course_code IN ('GE1', 'GE 1') AND COALESCE(course_type, 'REGULAR') = 'REGULAR';

UPDATE courses SET course_type = 'PETITION'
WHERE course_code LIKE 'PET-%' OR course_code LIKE 'PETITION%';

-- ── Demo student for holds / dean evaluation (minimal) ──────────────────────
SET @demo_sn := 'SPRINT-DEMO-2026-001';
SET @demo_ref := 'SPRINT-DEMO-REF-001';
SET @active_term := (SELECT term_id FROM academic_terms WHERE is_active = 1 LIMIT 1);

INSERT INTO students (
    student_number, reference_number, real_name, program_code,
    year_level, semester, enrollment_status_type, student_type
)
SELECT @demo_sn, @demo_ref, 'Sprint Demo Student', 'BSCPE', 1, 1, 'ENROLLED', 'REGULAR'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM students WHERE student_number = @demo_sn);

-- Sample OSA hold (cleared via Student Manager UI)
DELETE FROM student_holds
WHERE student_number = @demo_sn AND office = 'OSA' AND reason LIKE 'Demo hold%';

INSERT INTO student_holds (student_number, office, reason, active, created_by)
VALUES (@demo_sn, 'OSA', 'Demo hold — unreturned student ID (clear in Student Manager)', 1, 'bootstrap');

-- Library hold example (inactive — for UI reference)
INSERT INTO student_holds (student_number, office, reason, active, created_by)
SELECT @demo_sn, 'Library', 'Demo cleared hold — returned book', 0, 'bootstrap'
FROM DUAL
WHERE NOT EXISTS (
    SELECT 1 FROM student_holds
    WHERE student_number = @demo_sn AND office = 'Library'
);

-- ── Verification ────────────────────────────────────────────────────────────
SELECT 'ENROLLMENT PERIOD SETTINGS' AS section;
SELECT setting_key, setting_value
FROM system_settings
WHERE setting_key IN (
    'ENROLLMENT_OPEN_DATE', 'ENROLLMENT_CLOSE_DATE',
    'ADD_DROP_CLOSE_DATE', 'LATE_ENROLLMENT_FEE_ENABLED'
)
ORDER BY setting_key;

SELECT 'MIDTERM POLICY active term' AS section;
SELECT t.term_code, p.midterm_exam_date
FROM academic_terms t
LEFT JOIN academic_term_policies p ON p.term_id = t.term_id
WHERE t.is_active = 1;

SELECT 'COURSE TYPES sample' AS section;
SELECT course_code, course_type
FROM courses
WHERE course_type <> 'REGULAR'
LIMIT 10;

SELECT 'DEMO STUDENT HOLDS' AS section;
SELECT hold_id, student_number, office, active, reason
FROM student_holds
WHERE student_number = @demo_sn;

SELECT 'SPRINT_DEMO_SEED' AS status, 'OK' AS result;
