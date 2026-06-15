-- ============================================================
-- Year 3 Semester 1 grades — Elon Musk (2026-0002)
-- Section: BSIT-3-1-A | 6 subjects / 18 units
--
-- Prerequisite: Y3 S1 block enlist finalized after Registrar term transition.
-- HOW TO RUN: Select ALL (Ctrl+A) then Execute in MySQL Workbench on eacdb.
-- ============================================================
USE eacdb;

SET @student_id   = '2026-0002';
SET @section      = 'BSIT-3-1-A';
SET @graded_on    = '2027-12-15';
SET @student_name = COALESCE(
  (SELECT CONCAT(s.last_name, ', ', s.first_name) FROM students s WHERE s.student_number = @student_id LIMIT 1),
  'Musk, Elon'
);

DELETE g FROM grades g
INNER JOIN student_enlistments se ON g.student_id = se.student_id AND g.course_id = se.course_id
INNER JOIN class_sections cs ON se.section_id = cs.section_id
WHERE g.student_id = @student_id
  AND cs.section_code = @section;

INSERT INTO grades (
  student_id, course_id, section_id,
  prelim, midterm, final_grade, semestral_grade,
  grade, remarks, status, date_recorded, student_name
)
SELECT @student_id, se.course_id, se.section_id,
       gm.prelim, gm.midterm, gm.final_grade, gm.semestral_grade,
       gm.semestral_grade, 'Passed', 'PASSED', @graded_on, @student_name
FROM student_enlistments se
INNER JOIN courses c ON c.course_id = se.course_id
INNER JOIN class_sections cs ON cs.section_id = se.section_id
INNER JOIN (
  SELECT 'SMA3 21' AS course_code, 85 AS prelim, 87 AS midterm, 89 AS final_grade, 1.75 AS semestral_grade
  UNION ALL SELECT 'USI1 31', 86, 88, 90, 1.75
  UNION ALL SELECT 'UNW2 31', 87, 89, 91, 1.50
  UNION ALL SELECT 'UEL2 31', 84, 86, 88, 1.75
  UNION ALL SELECT 'UEL131',  88, 90, 92, 1.50
  UNION ALL SELECT 'UDB231',  86, 88, 90, 1.75
) gm ON gm.course_code = c.course_code
WHERE se.student_id = @student_id
  AND cs.section_code = @section;

SELECT c.course_code, c.course_title, c.credit_units, g.prelim, g.midterm, g.final_grade, g.semestral_grade, g.status
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
