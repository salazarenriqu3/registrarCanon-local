-- ============================================================
-- Year 3 Semester 1 grades — Maria Santos (2026-1001)
-- Section: BSIT-3-1-A | 6 subjects (SET BSIT official)
-- Prerequisite: 00_seed_bsit_curriculum_set_official.sql + 01_seed_bsit_class_sections_demo.sql
-- Run during demo after Y3S1 block enroll.
-- ============================================================
USE eacdb;

SET @student_id   = '2026-1001';
SET @student_name = 'Maria Reyes Santos';
SET @section      = 'BSIT-3-1-A';
SET @graded_on    = '2027-12-15';

INSERT IGNORE INTO grades (student_id, course_id, section_id, prelim, midterm, final_grade, semestral_grade, grade, remarks, status, date_recorded, student_name)
SELECT @student_id, c.course_id,
  COALESCE((SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code = @section LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code LIKE 'BSIT-3-1%' LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id LIMIT 1)),
  v.prelim, v.midterm, v.final_grade, v.semestral_grade, v.semestral_grade, 'Passed', 'PASSED', @graded_on, @student_name
FROM (SELECT 'SMA3 21' AS course_code, 85 AS prelim, 87 AS midterm, 89 AS final_grade, 1.75 AS semestral_grade) v
JOIN courses c ON c.course_code = v.course_code;
INSERT IGNORE INTO grades (student_id, course_id, section_id, prelim, midterm, final_grade, semestral_grade, grade, remarks, status, date_recorded, student_name)
SELECT @student_id, c.course_id,
  COALESCE((SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code = @section LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code LIKE 'BSIT-3-1%' LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id LIMIT 1)),
  v.prelim, v.midterm, v.final_grade, v.semestral_grade, v.semestral_grade, 'Passed', 'PASSED', @graded_on, @student_name
FROM (SELECT 'USI1 31' AS course_code, 86 AS prelim, 88 AS midterm, 90 AS final_grade, 1.75 AS semestral_grade) v
JOIN courses c ON c.course_code = v.course_code;
INSERT IGNORE INTO grades (student_id, course_id, section_id, prelim, midterm, final_grade, semestral_grade, grade, remarks, status, date_recorded, student_name)
SELECT @student_id, c.course_id,
  COALESCE((SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code = @section LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code LIKE 'BSIT-3-1%' LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id LIMIT 1)),
  v.prelim, v.midterm, v.final_grade, v.semestral_grade, v.semestral_grade, 'Passed', 'PASSED', @graded_on, @student_name
FROM (SELECT 'UNW2 31' AS course_code, 84 AS prelim, 86 AS midterm, 88 AS final_grade, 1.75 AS semestral_grade) v
JOIN courses c ON c.course_code = v.course_code;
INSERT IGNORE INTO grades (student_id, course_id, section_id, prelim, midterm, final_grade, semestral_grade, grade, remarks, status, date_recorded, student_name)
SELECT @student_id, c.course_id,
  COALESCE((SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code = @section LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code LIKE 'BSIT-3-1%' LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id LIMIT 1)),
  v.prelim, v.midterm, v.final_grade, v.semestral_grade, v.semestral_grade, 'Passed', 'PASSED', @graded_on, @student_name
FROM (SELECT 'UEL2 31' AS course_code, 87 AS prelim, 89 AS midterm, 91 AS final_grade, 1.5 AS semestral_grade) v
JOIN courses c ON c.course_code = v.course_code;
INSERT IGNORE INTO grades (student_id, course_id, section_id, prelim, midterm, final_grade, semestral_grade, grade, remarks, status, date_recorded, student_name)
SELECT @student_id, c.course_id,
  COALESCE((SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code = @section LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code LIKE 'BSIT-3-1%' LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id LIMIT 1)),
  v.prelim, v.midterm, v.final_grade, v.semestral_grade, v.semestral_grade, 'Passed', 'PASSED', @graded_on, @student_name
FROM (SELECT 'UEL131' AS course_code, 88 AS prelim, 90 AS midterm, 92 AS final_grade, 1.5 AS semestral_grade) v
JOIN courses c ON c.course_code = v.course_code;
INSERT IGNORE INTO grades (student_id, course_id, section_id, prelim, midterm, final_grade, semestral_grade, grade, remarks, status, date_recorded, student_name)
SELECT @student_id, c.course_id,
  COALESCE((SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code = @section LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code LIKE 'BSIT-3-1%' LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id LIMIT 1)),
  v.prelim, v.midterm, v.final_grade, v.semestral_grade, v.semestral_grade, 'Passed', 'PASSED', @graded_on, @student_name
FROM (SELECT 'UDB231' AS course_code, 83 AS prelim, 85 AS midterm, 87 AS final_grade, 2 AS semestral_grade) v
JOIN courses c ON c.course_code = v.course_code;
-- Verify (6 rows expected for this term slice)
SELECT c.course_code, g.semestral_grade, g.status
FROM grades g
JOIN courses c ON g.course_id = c.course_id
WHERE g.student_id = @student_id
  AND c.course_code IN ('SMA3 21', 'USI1 31', 'UNW2 31', 'UEL2 31', 'UEL131', 'UDB231')
ORDER BY c.course_code;
