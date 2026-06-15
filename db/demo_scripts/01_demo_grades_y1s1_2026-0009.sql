-- ============================================================
-- Year 1 Semester 1 grades — Student 2026-0009 (BSN)
-- Section: BSN-1-1-A  |  subjects from enrolled block
--
-- Prerequisite: Y1 S1 block enlist finalized in Enrollment Cashier.
-- HOW TO RUN: Select ALL (Ctrl+A) then Execute in MySQL Workbench.
-- ============================================================
SET NAMES utf8mb4 COLLATE utf8mb4_general_ci;
USE eacdb;

SET @student_id   = '2026-0009';
SET @section      = 'BSN-1-1-A';
SET @graded_on    = '2025-12-15';
SET @student_name = COALESCE(
  (SELECT CONCAT(s.last_name, ', ', s.first_name) FROM students s WHERE s.student_number = @student_id LIMIT 1),
  'Student, 2026-0009'
);

-- Remove prior Y1 S1 grades for courses enlisted in this block section
DELETE g FROM grades g
INNER JOIN student_enlistments se ON g.student_id = se.student_id AND g.course_id = se.course_id
INNER JOIN class_sections cs ON se.section_id = cs.section_id
WHERE g.student_id = @student_id
  AND cs.section_code = @section;

-- Seed PASSED grades (grades derived from the BSN Y1S1 block section subjects)
INSERT INTO grades (
  student_id, course_id, section_id,
  prelim, midterm, final_grade, semestral_grade,
  grade, remarks, status, date_recorded, student_name
)
SELECT
  @student_id,
  se.course_id,
  se.section_id,
  gm.prelim,
  gm.midterm,
  gm.final_grade,
  gm.semestral_grade,
  gm.semestral_grade,
  'Passed',
  'PASSED',
  @graded_on,
  @student_name
FROM student_enlistments se
INNER JOIN courses c ON c.course_id = se.course_id
INNER JOIN class_sections cs ON cs.section_id = se.section_id
INNER JOIN (
  -- Common BSN Y1S1 subjects — adjust course_codes to match your curriculum
  SELECT 'ANP1 11'  AS course_code, 85 AS prelim, 87 AS midterm, 88 AS final_grade, 1.75 AS semestral_grade
  UNION ALL SELECT 'AHU1 11',  88, 89, 90, 1.5
  UNION ALL SELECT 'ANSC 11',  86, 87, 88, 1.75
  UNION ALL SELECT 'ARPH 11',  85, 86, 88, 1.75
  UNION ALL SELECT 'ANS1 11',  87, 88, 89, 1.5
  UNION ALL SELECT 'AFCO 11',  86, 87, 88, 1.75
  UNION ALL SELECT 'AECO 11',  86, 87, 88, 1.75
  UNION ALL SELECT 'AFC0 11',  86, 87, 88, 1.75
  UNION ALL SELECT 'PE1 11',   90, 91, 92, 1.25
  UNION ALL SELECT 'SMMW 11',  84, 86, 88, 1.75
  UNION ALL SELECT 'UCO1 11',  84, 86, 88, 1.75
  UNION ALL SELECT 'UPR1 11',  80, 83, 85, 2.0
) gm ON gm.course_code = c.course_code
WHERE se.student_id = @student_id
  AND cs.section_code = @section;

-- Verify (expect rows equal to number of enlisted subjects)
SELECT
  c.course_code,
  c.course_title,
  g.prelim,
  g.midterm,
  g.final_grade,
  g.semestral_grade,
  g.status
FROM grades g
INNER JOIN courses c ON g.course_id = c.course_id
INNER JOIN student_enlistments se ON se.student_id = g.student_id AND se.course_id = g.course_id
INNER JOIN class_sections cs ON cs.section_id = se.section_id
WHERE g.student_id = @student_id
  AND cs.section_code = @section
ORDER BY c.course_code;

SELECT
  (SELECT COUNT(*) FROM student_enlistments se
   INNER JOIN class_sections cs ON cs.section_id = se.section_id
   WHERE se.student_id = @student_id AND cs.section_code = @section) AS enlisted_subjects,
  (SELECT COUNT(*) FROM grades g
   INNER JOIN student_enlistments se ON se.student_id = g.student_id AND se.course_id = g.course_id
   INNER JOIN class_sections cs ON cs.section_id = se.section_id
   WHERE g.student_id = @student_id AND cs.section_code = @section) AS graded_subjects;
