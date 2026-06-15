-- ============================================================
-- Year 1 Semester 1 grades — Maria Santos (2026-1001)
-- Section: BSIT-1-1-A | 10 subjects (SET BSIT official)
-- Prerequisite: 00_seed_bsit_curriculum_set_official.sql + 01_seed_bsit_class_sections_demo.sql
-- Run during demo after Y1S1 block enroll.
-- ============================================================
USE eacdb;

SET @student_id   = '2026-1001';
SET @student_name = 'Maria Reyes Santos';
SET @section      = 'BSIT-1-1-A';
SET @graded_on    = '2025-12-15';

INSERT IGNORE INTO grades (student_id, course_id, section_id, prelim, midterm, final_grade, semestral_grade, grade, remarks, status, date_recorded, student_name)
SELECT @student_id, c.course_id,
  COALESCE((SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code = @section LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code LIKE 'BSIT-1-1%' LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id LIMIT 1)),
  v.prelim, v.midterm, v.final_grade, v.semestral_grade, v.semestral_grade, 'Passed', 'PASSED', @graded_on, @student_name
FROM (SELECT 'AUS0 11' AS course_code, 90 AS prelim, 88 AS midterm, 92 AS final_grade, 1.25 AS semestral_grade) v
JOIN courses c ON c.course_code = v.course_code;
INSERT IGNORE INTO grades (student_id, course_id, section_id, prelim, midterm, final_grade, semestral_grade, grade, remarks, status, date_recorded, student_name)
SELECT @student_id, c.course_id,
  COALESCE((SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code = @section LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code LIKE 'BSIT-1-1%' LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id LIMIT 1)),
  v.prelim, v.midterm, v.final_grade, v.semestral_grade, v.semestral_grade, 'Passed', 'PASSED', @graded_on, @student_name
FROM (SELECT 'ARPH 11' AS course_code, 85 AS prelim, 87 AS midterm, 89 AS final_grade, 1.5 AS semestral_grade) v
JOIN courses c ON c.course_code = v.course_code;
INSERT IGNORE INTO grades (student_id, course_id, section_id, prelim, midterm, final_grade, semestral_grade, grade, remarks, status, date_recorded, student_name)
SELECT @student_id, c.course_id,
  COALESCE((SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code = @section LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code LIKE 'BSIT-1-1%' LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id LIMIT 1)),
  v.prelim, v.midterm, v.final_grade, v.semestral_grade, v.semestral_grade, 'Passed', 'PASSED', @graded_on, @student_name
FROM (SELECT 'SMMW 11' AS course_code, 84 AS prelim, 86 AS midterm, 88 AS final_grade, 1.75 AS semestral_grade) v
JOIN courses c ON c.course_code = v.course_code;
INSERT IGNORE INTO grades (student_id, course_id, section_id, prelim, midterm, final_grade, semestral_grade, grade, remarks, status, date_recorded, student_name)
SELECT @student_id, c.course_id,
  COALESCE((SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code = @section LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code LIKE 'BSIT-1-1%' LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id LIMIT 1)),
  v.prelim, v.midterm, v.final_grade, v.semestral_grade, v.semestral_grade, 'Passed', 'PASSED', @graded_on, @student_name
FROM (SELECT 'AHU1 11' AS course_code, 88 AS prelim, 89 AS midterm, 90 AS final_grade, 1.5 AS semestral_grade) v
JOIN courses c ON c.course_code = v.course_code;
INSERT IGNORE INTO grades (student_id, course_id, section_id, prelim, midterm, final_grade, semestral_grade, grade, remarks, status, date_recorded, student_name)
SELECT @student_id, c.course_id,
  COALESCE((SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code = @section LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code LIKE 'BSIT-1-1%' LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id LIMIT 1)),
  v.prelim, v.midterm, v.final_grade, v.semestral_grade, v.semestral_grade, 'Passed', 'PASSED', @graded_on, @student_name
FROM (SELECT 'ASS1011' AS course_code, 83 AS prelim, 85 AS midterm, 87 AS final_grade, 2 AS semestral_grade) v
JOIN courses c ON c.course_code = v.course_code;
INSERT IGNORE INTO grades (student_id, course_id, section_id, prelim, midterm, final_grade, semestral_grade, grade, remarks, status, date_recorded, student_name)
SELECT @student_id, c.course_id,
  COALESCE((SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code = @section LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code LIKE 'BSIT-1-1%' LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id LIMIT 1)),
  v.prelim, v.midterm, v.final_grade, v.semestral_grade, v.semestral_grade, 'Passed', 'PASSED', @graded_on, @student_name
FROM (SELECT 'PE1 11' AS course_code, 90 AS prelim, 91 AS midterm, 92 AS final_grade, 1.25 AS semestral_grade) v
JOIN courses c ON c.course_code = v.course_code;
INSERT IGNORE INTO grades (student_id, course_id, section_id, prelim, midterm, final_grade, semestral_grade, grade, remarks, status, date_recorded, student_name)
SELECT @student_id, c.course_id,
  COALESCE((SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code = @section LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code LIKE 'BSIT-1-1%' LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id LIMIT 1)),
  v.prelim, v.midterm, v.final_grade, v.semestral_grade, v.semestral_grade, 'Passed', 'PASSED', @graded_on, @student_name
FROM (SELECT 'ANS1 11' AS course_code, 87 AS prelim, 88 AS midterm, 89 AS final_grade, 1.5 AS semestral_grade) v
JOIN courses c ON c.course_code = v.course_code;
INSERT IGNORE INTO grades (student_id, course_id, section_id, prelim, midterm, final_grade, semestral_grade, grade, remarks, status, date_recorded, student_name)
SELECT @student_id, c.course_id,
  COALESCE((SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code = @section LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code LIKE 'BSIT-1-1%' LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id LIMIT 1)),
  v.prelim, v.midterm, v.final_grade, v.semestral_grade, v.semestral_grade, 'Passed', 'PASSED', @graded_on, @student_name
FROM (SELECT 'AECO 11' AS course_code, 86 AS prelim, 87 AS midterm, 88 AS final_grade, 1.75 AS semestral_grade) v
JOIN courses c ON c.course_code = v.course_code;
INSERT IGNORE INTO grades (student_id, course_id, section_id, prelim, midterm, final_grade, semestral_grade, grade, remarks, status, date_recorded, student_name)
SELECT @student_id, c.course_id,
  COALESCE((SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code = @section LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code LIKE 'BSIT-1-1%' LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id LIMIT 1)),
  v.prelim, v.midterm, v.final_grade, v.semestral_grade, v.semestral_grade, 'Passed', 'PASSED', @graded_on, @student_name
FROM (SELECT 'UCO1 11' AS course_code, 84 AS prelim, 86 AS midterm, 88 AS final_grade, 1.75 AS semestral_grade) v
JOIN courses c ON c.course_code = v.course_code;
INSERT IGNORE INTO grades (student_id, course_id, section_id, prelim, midterm, final_grade, semestral_grade, grade, remarks, status, date_recorded, student_name)
SELECT @student_id, c.course_id,
  COALESCE((SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code = @section LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id AND cs.section_code LIKE 'BSIT-1-1%' LIMIT 1),
           (SELECT cs.section_id FROM class_sections cs WHERE cs.course_id = c.course_id LIMIT 1)),
  v.prelim, v.midterm, v.final_grade, v.semestral_grade, v.semestral_grade, 'Passed', 'PASSED', @graded_on, @student_name
FROM (SELECT 'UPR1 11' AS course_code, 80 AS prelim, 83 AS midterm, 85 AS final_grade, 2 AS semestral_grade) v
JOIN courses c ON c.course_code = v.course_code;
-- Verify (10 rows expected for this term slice)
SELECT c.course_code, g.semestral_grade, g.status
FROM grades g
JOIN courses c ON g.course_id = c.course_id
WHERE g.student_id = @student_id
  AND c.course_code IN ('AUS0 11', 'ARPH 11', 'SMMW 11', 'AHU1 11', 'ASS1011', 'PE1 11', 'ANS1 11', 'AECO 11', 'UCO1 11', 'UPR1 11')
ORDER BY c.course_code;
