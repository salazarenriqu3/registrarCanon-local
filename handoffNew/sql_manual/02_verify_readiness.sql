-- Run after each configuration step to see what's still blocking readiness
USE eacdb;

SELECT 'ACTIVE TERM' AS check_name, term_id, term_code, is_active
FROM academic_terms WHERE is_active = 1;

SELECT 'SETTING' AS check_name, setting_key, setting_value
FROM system_settings WHERE setting_key = 'CURRENT_ACADEMIC_TERM';

SELECT 'PROGRAMS' AS check_name, program_code, active_status
FROM programs WHERE program_code IN ('BSIT','BSCPE','BSBA','BSCS')
ORDER BY program_code;

SELECT 'FEE ROWS active term' AS check_name, COUNT(*) AS cnt
FROM program_fee_settings pfs
JOIN academic_terms t ON t.term_id = pfs.term_id AND t.is_active = 1;

SELECT 'CURRICULA with courses' AS check_name, p.program_code, ct.curriculum_id,
       (SELECT COUNT(*) FROM curriculum_courses cc WHERE cc.curriculum_id = ct.curriculum_id) AS course_rows
FROM programs p
JOIN curriculum_templates ct ON ct.program_id = p.program_id AND COALESCE(ct.is_active,0)=1
WHERE COALESCE(p.active_status,1)=1
ORDER BY p.program_code
LIMIT 25;

SELECT 'BLOCK SECTIONS active term' AS check_name, COUNT(*) AS cnt
FROM class_sections cs
JOIN academic_terms t ON t.term_id = cs.term_id AND t.is_active = 1
WHERE cs.section_code REGEXP '-[0-9]-[0-9]-[A-D]$';

SELECT 'UNSCHEDULED (TBA) active term' AS check_name, COUNT(*) AS cnt
FROM class_sections cs
JOIN academic_terms t ON t.term_id = cs.term_id AND t.is_active = 1
WHERE NOT EXISTS (SELECT 1 FROM class_schedules sch WHERE sch.section_id = cs.section_id);
