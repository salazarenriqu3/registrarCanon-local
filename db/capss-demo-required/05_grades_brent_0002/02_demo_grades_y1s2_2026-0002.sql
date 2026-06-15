-- ============================================================
-- Year 1 Semester 2 grades — Elon Musk (2026-0002)
-- Section: BSIT-1-2-A | 8 subjects / 23 units (matches enlistment terminal)
--
-- Subjects: AET0 12, ANS2 12, APC0 12, PE2 12, SMST012, UADET 32, UHC1 11, UPR2 12
--
-- Prerequisite: Y1 S2 block enlist finalized; run after 01_demo_grades_y1s1_2026-0002.sql
--               and term transition to SL_2120242025 (Y1 2nd sem).
--
-- HOW TO RUN: Select ALL (Ctrl+A) then Execute in MySQL Workbench on eacdb.
-- ============================================================
USE eacdb;

SET @student_id   = '2026-0002';
SET @section      = 'BSIT-1-2-A';
SET @graded_on    = '2026-05-15';
SET @student_name = COALESCE(
  (SELECT CONCAT(s.last_name, ', ', s.first_name) FROM students s WHERE s.student_number = @student_id LIMIT 1),
  'Musk, Elon'
);

-- Remove prior Y1 S2 grades for courses enlisted in this block section
DELETE g FROM grades g
INNER JOIN student_enlistments se ON g.student_id = se.student_id AND g.course_id = se.course_id
INNER JOIN class_sections cs ON se.section_id = cs.section_id
WHERE g.student_id = @student_id
  AND cs.section_code = @section;

-- Seed PASSED grades from current enlistment
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
  SELECT 'AET0 12'   AS course_code, 87 AS prelim, 89 AS midterm, 91 AS final_grade, 1.5  AS semestral_grade
  UNION ALL SELECT 'ANS2 12',  85, 86, 88, 1.75
  UNION ALL SELECT 'APC0 12',  85, 87, 89, 1.75
  UNION ALL SELECT 'PE2 12',   90, 91, 92, 1.25
  UNION ALL SELECT 'SMST012',  84, 86, 88, 1.75
  UNION ALL SELECT 'UADET 32', 86, 88, 90, 1.75
  UNION ALL SELECT 'UHC1 11',  82, 84, 86, 2.0
  UNION ALL SELECT 'UPR2 12',  88, 90, 92, 1.5
  -- Official SET Y1 S2 alternate (if block uses ACW0 instead of UADET)
  UNION ALL SELECT 'ACW0 12',  86, 88, 90, 1.75
) gm ON gm.course_code = c.course_code
WHERE se.student_id = @student_id
  AND cs.section_code = @section;

-- Verify (expect 8 rows)
SELECT
  c.course_code,
  c.course_title,
  c.credit_units,
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
  (SELECT COALESCE(SUM(c.credit_units), 0) FROM student_enlistments se
   INNER JOIN courses c ON c.course_id = se.course_id
   INNER JOIN class_sections cs ON cs.section_id = se.section_id
   WHERE se.student_id = @student_id AND cs.section_code = @section) AS enlisted_units,
  (SELECT COUNT(*) FROM grades g
   INNER JOIN student_enlistments se ON se.student_id = g.student_id AND se.course_id = g.course_id
   INNER JOIN class_sections cs ON cs.section_id = se.section_id
   WHERE g.student_id = @student_id AND cs.section_code = @section) AS graded_subjects;
