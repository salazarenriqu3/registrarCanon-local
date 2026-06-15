-- ============================================================
-- Year 3 Semester 2 grades — Elon Musk (2026-0003)
-- Section: BSIT-3-2-A | 5 subjects per SET BSIT official curriculum (Y3 S2)
-- Prerequisite: 00_seed_bsit_curriculum_set_official.sql + 01_seed_bsit_class_sections_demo.sql on eacdb
--
-- HOW TO RUN (MySQL Workbench): open this file → Execute (entire script).
-- ============================================================
USE eacdb;

SET @student_id   = '2026-0003';
SET @student_name = 'Elon Musk';
SET @section      = 'BSIT-3-2-A';
SET @graded_on    = '2028-05-15';

INSERT IGNORE INTO grades (student_id, course_id, section_id, prelim, midterm, final_grade, semestral_grade, grade, remarks, status, date_recorded, student_name)
SELECT @student_id, c.course_id,
  COALESCE((SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code = @section LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code LIKE 'BSIT-3-2%' LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id LIMIT 1)),
  v.prelim, v.midterm, v.final_grade, v.semestral_grade, v.semestral_grade, 'Passed', 'PASSED', @graded_on, @student_name
FROM (SELECT 'UADET 32' AS course_code, 86 AS prelim, 88 AS midterm, 90 AS final_grade, 1.75 AS semestral_grade) v
JOIN courses c ON c.course_code = v.course_code;
INSERT IGNORE INTO grades (student_id, course_id, section_id, prelim, midterm, final_grade, semestral_grade, grade, remarks, status, date_recorded, student_name)
SELECT @student_id, c.course_id,
  COALESCE((SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code = @section LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code LIKE 'BSIT-3-2%' LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id LIMIT 1)),
  v.prelim, v.midterm, v.final_grade, v.semestral_grade, v.semestral_grade, 'Passed', 'PASSED', @graded_on, @student_name
FROM (SELECT 'UEDP0 32' AS course_code, 85 AS prelim, 87 AS midterm, 89 AS final_grade, 1.75 AS semestral_grade) v
JOIN courses c ON c.course_code = v.course_code;
INSERT IGNORE INTO grades (student_id, course_id, section_id, prelim, midterm, final_grade, semestral_grade, grade, remarks, status, date_recorded, student_name)
SELECT @student_id, c.course_id,
  COALESCE((SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code = @section LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code LIKE 'BSIT-3-2%' LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id LIMIT 1)),
  v.prelim, v.midterm, v.final_grade, v.semestral_grade, v.semestral_grade, 'Passed', 'PASSED', @graded_on, @student_name
FROM (SELECT 'UIAS1 32' AS course_code, 84 AS prelim, 86 AS midterm, 88 AS final_grade, 1.75 AS semestral_grade) v
JOIN courses c ON c.course_code = v.course_code;
INSERT IGNORE INTO grades (student_id, course_id, section_id, prelim, midterm, final_grade, semestral_grade, grade, remarks, status, date_recorded, student_name)
SELECT @student_id, c.course_id,
  COALESCE((SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code = @section LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code LIKE 'BSIT-3-2%' LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id LIMIT 1)),
  v.prelim, v.midterm, v.final_grade, v.semestral_grade, v.semestral_grade, 'Passed', 'PASSED', @graded_on, @student_name
FROM (SELECT 'UQM0 32' AS course_code, 87 AS prelim, 89 AS midterm, 91 AS final_grade, 1.5 AS semestral_grade) v
JOIN courses c ON c.course_code = v.course_code;
INSERT IGNORE INTO grades (student_id, course_id, section_id, prelim, midterm, final_grade, semestral_grade, grade, remarks, status, date_recorded, student_name)
SELECT @student_id, c.course_id,
  COALESCE((SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code = @section LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code LIKE 'BSIT-3-2%' LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id LIMIT 1)),
  v.prelim, v.midterm, v.final_grade, v.semestral_grade, v.semestral_grade, 'Passed', 'PASSED', @graded_on, @student_name
FROM (SELECT 'USPI 32' AS course_code, 88 AS prelim, 90 AS midterm, 92 AS final_grade, 1.5 AS semestral_grade) v
JOIN courses c ON c.course_code = v.course_code;
-- Verify (5 rows expected for this term slice)
SELECT c.course_code, g.semestral_grade, g.status
FROM grades g
JOIN courses c ON g.course_id = c.course_id
WHERE g.student_id = @student_id
  AND c.course_code IN ('UADET 32', 'UEDP0 32', 'UIAS1 32', 'UQM0 32', 'USPI 32')
ORDER BY c.course_code;

