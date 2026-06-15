-- =============================================================================
-- BSN current-term grades — reusable lifecycle seed
--
-- Use this before each Registrar term transition.
-- Change @student_id to the BSN demo student you are testing.
--
-- Flow:
--   1. Block-enlist/finalize BSN student for current term.
--   2. Run this script.
--   3. Verify graded_subjects = enlisted_subjects.
--   4. Trigger Registrar term transition.
--   5. Repeat next term.
-- =============================================================================
USE eacdb;

SET @student_id = '2026-0003'; -- Change to your BSN demo student number.

SET @year_level = (
    SELECT COALESCE(year_level, 1)
    FROM students
    WHERE student_number = @student_id
    LIMIT 1
);

SET @semester = (
    SELECT COALESCE(semester, 1)
    FROM students
    WHERE student_number = @student_id
    LIMIT 1
);

SET @section = CONCAT('BSN-', @year_level, '-', @semester, '-A');

SET @graded_on = CURDATE();

SET @student_name = COALESCE(
  (SELECT CONCAT(s.last_name, ', ', s.first_name)
   FROM students s
   WHERE s.student_number = @student_id
   LIMIT 1),
  @student_id
);

-- Remove prior grades only for the student's current BSN block section.
DELETE g FROM grades g
INNER JOIN student_enlistments se ON g.student_id = se.student_id AND g.course_id = se.course_id
INNER JOIN class_sections cs ON se.section_id = cs.section_id
WHERE g.student_id = @student_id
  AND cs.section_code = @section;

-- Seed passing grades for whatever courses are currently enlisted in this BSN block.
INSERT INTO grades (
  student_id, course_id, section_id,
  prelim, midterm, final_grade, semestral_grade,
  grade, remarks, status, date_recorded, student_name
)
SELECT
  @student_id,
  q.course_id,
  q.section_id,
  q.prelim,
  q.midterm,
  q.final_grade,
  q.semestral_grade,
  q.semestral_grade,
  'Passed',
  'PASSED',
  @graded_on,
  @student_name
FROM (
    SELECT
        se.course_id,
        se.section_id,
        84 + (ROW_NUMBER() OVER (ORDER BY c.course_code) % 7) AS prelim,
        86 + (ROW_NUMBER() OVER (ORDER BY c.course_code) % 7) AS midterm,
        88 + (ROW_NUMBER() OVER (ORDER BY c.course_code) % 7) AS final_grade,
        CASE ROW_NUMBER() OVER (ORDER BY c.course_code) % 5
            WHEN 0 THEN 1.25
            WHEN 1 THEN 1.50
            WHEN 2 THEN 1.75
            WHEN 3 THEN 2.00
            ELSE 2.25
        END AS semestral_grade
    FROM student_enlistments se
    INNER JOIN courses c ON c.course_id = se.course_id
    INNER JOIN class_sections cs ON cs.section_id = se.section_id
    WHERE se.student_id = @student_id
      AND cs.section_code = @section
) q;

-- Verify current term.
SELECT
  @student_id AS student_id,
  @student_name AS student_name,
  @year_level AS year_level,
  @semester AS semester,
  @section AS section_code;

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
