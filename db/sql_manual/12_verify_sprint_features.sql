-- Post-migration / post-bootstrap verification for Sprint 1–10 features.
USE eacdb;

SELECT '=== TABLE EXISTS ===' AS section;

SELECT 'grading_schemes' AS object_name,
       CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM information_schema.tables
WHERE table_schema = DATABASE() AND table_name = 'grading_schemes';

SELECT 'student_holds' AS object_name,
       CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM information_schema.tables
WHERE table_schema = DATABASE() AND table_name = 'student_holds';

SELECT 'student_program_shift_requests' AS object_name,
       CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM information_schema.tables
WHERE table_schema = DATABASE() AND table_name = 'student_program_shift_requests';

SELECT '=== COLUMNS ===' AS section;

SELECT 'programs.duration_years' AS object_name,
       CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM information_schema.columns
WHERE table_schema = DATABASE() AND table_name = 'programs' AND column_name = 'duration_years';

SELECT 'courses.course_type' AS object_name,
       CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM information_schema.columns
WHERE table_schema = DATABASE() AND table_name = 'courses' AND column_name = 'course_type';

SELECT 'academic_term_policies.midterm_exam_date' AS object_name,
       CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM information_schema.columns
WHERE table_schema = DATABASE() AND table_name = 'academic_term_policies' AND column_name = 'midterm_exam_date';

SELECT '=== SETTINGS ===' AS section;

SELECT setting_key, setting_value,
       CASE WHEN setting_key IS NOT NULL THEN 'PASS' ELSE 'FAIL' END AS status
FROM system_settings
WHERE setting_key IN (
    'ENROLLMENT_OPEN_DATE', 'ENROLLMENT_CLOSE_DATE',
    'ADD_DROP_CLOSE_DATE', 'LATE_ENROLLMENT_FEE_ENABLED'
)
ORDER BY setting_key;

SELECT 'drop_penalty_first_week_percent' AS setting_key,
       setting_value,
       CASE WHEN setting_value IS NOT NULL THEN 'PASS' ELSE 'FAIL' END AS status
FROM enrollment_settings
WHERE setting_key = 'drop_penalty_first_week_percent';

SELECT '=== DEFAULT GRADING SCHEME ===' AS section;

SELECT scheme_id, program_code, class_standing_percent, exam_percent, base_scale
FROM grading_schemes
WHERE program_code IS NULL;

SELECT '=== WITHDRAWAL REASONS ===' AS section;

SELECT COUNT(*) AS active_reason_count FROM withdrawal_reasons WHERE COALESCE(is_active, 1) = 1;

SELECT '=== SPRINT VERIFY COMPLETE ===' AS section;
