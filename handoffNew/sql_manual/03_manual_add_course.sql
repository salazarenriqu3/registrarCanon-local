-- Manual configuration: add ONE course to the catalog (demo Course Catalog UI equivalent)
-- Batch alternative: registrar/db/04_seed_full_curriculum.sql
USE eacdb;

SET @dept_id = (SELECT department_id FROM departments ORDER BY department_id LIMIT 1);

INSERT INTO courses (course_code, course_title, credit_units, department_id, active_status, onlist)
SELECT 'DEMO 101', 'Demo Manual Configuration Course', 3, @dept_id, 1, 1
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM courses WHERE course_code = 'DEMO 101');

SELECT course_id, course_code, course_title, credit_units, active_status
FROM courses WHERE course_code = 'DEMO 101';

-- UI follow-up: attach DEMO 101 in Curriculum builder via course picker
-- /admin/curriculum/view/{curriculum_id}
