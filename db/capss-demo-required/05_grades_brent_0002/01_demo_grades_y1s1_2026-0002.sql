-- ============================================================
-- Year 1 Semester 1 grades — Elon Musk (2026-0002)
-- Section: BSIT-1-1-A | 10 subjects (matches enlistment terminal)
--
-- | Code     | Title                                      | Prelim | Midterm | Final | Semestral |
-- |----------|--------------------------------------------|--------|---------|-------|-----------|
-- | AECO 11  | Emilian Culture                            | 86     | 87      | 88    | 1.75      |
-- | AHU1 11  | Art Appreciation                           | 88     | 89      | 90    | 1.50      |
-- | ANS1 11  | CWTS 1/LTS 1/ROTC 1                        | 87     | 88      | 89    | 1.50      |
-- | ARPH 11  | Readings in Philippine History             | 85     | 87      | 89    | 1.50      |
-- | ASS1011  | Social Sciences and Philosophy             | 83     | 85      | 87    | 2.00      |
-- | AUSO 11  | Understanding the Self                     | 90     | 88      | 92    | 1.25      |
-- | PE1 11   | PE 1 (PATHFit 1)                           | 90     | 91      | 92    | 1.25      |
-- | SMMW 11  | Mathematics in the Modern World            | 84     | 86      | 88    | 1.75      |
-- | UCO1 11  | Introduction to Information Technology     | 84     | 86      | 88    | 1.75      |
-- | UPR1 11  | Fundamentals of Problem Solving & Prog.    | 80     | 83      | 85    | 2.00      |
--
-- Prerequisite: Y1 S1 block enlist finalized in Enrollment Cashier first.
--               Fresh install: db/fix → capss-demo-required/01_setup/01_fresh_demo_bootstrap.sql →
--               capss-demo-required/01_setup/02_bsit_full_align_term_and_curriculum.sql → seed_program_fees…
--
-- HOW TO RUN: Select ALL (Ctrl+A) then Execute in MySQL Workbench.
-- ============================================================
SET NAMES utf8mb4 COLLATE utf8mb4_general_ci;
USE eacdb;

SET @student_id   = '2026-0002';
SET @section      = 'BSIT-1-1-A';
SET @graded_on    = '2025-12-15';
SET @student_name = COALESCE(
  (SELECT CONCAT(s.last_name, ', ', s.first_name) FROM students s WHERE s.student_number = @student_id LIMIT 1),
  'Musk, Elon'
);

-- Remove prior Y1 S1 grades for courses enlisted in this block section
DELETE g FROM grades g
INNER JOIN student_enlistments se ON g.student_id = se.student_id AND g.course_id = se.course_id
INNER JOIN class_sections cs ON se.section_id = cs.section_id
WHERE g.student_id = @student_id
  AND cs.section_code = @section;

-- Seed PASSED grades from current enlistment (works with AFCO/AECO and AUSO/AUS0 codes)
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
  SELECT 'AFCO 11'  AS course_code, 86 AS prelim, 87 AS midterm, 88 AS final_grade, 1.75 AS semestral_grade
  UNION ALL SELECT 'AECO 11',  86, 87, 88, 1.75
  UNION ALL SELECT 'AFC0 11',  86, 87, 88, 1.75
  UNION ALL SELECT 'AHU1 11',  88, 89, 90, 1.5
  UNION ALL SELECT 'ANS1 11',  87, 88, 89, 1.5
  UNION ALL SELECT 'ARPH 11',  85, 87, 89, 1.5
  UNION ALL SELECT 'ASS1011',  83, 85, 87, 2.0
  UNION ALL SELECT 'AUSO 11',  90, 88, 92, 1.25
  UNION ALL SELECT 'AUS0 11',  90, 88, 92, 1.25
  UNION ALL SELECT 'PE1 11',   90, 91, 92, 1.25
  UNION ALL SELECT 'SMMW 11',  84, 86, 88, 1.75
  UNION ALL SELECT 'UCO1 11',  84, 86, 88, 1.75
  UNION ALL SELECT 'UPR1 11',  80, 83, 85, 2.0
  UNION ALL SELECT 'UPRI1 11', 80, 83, 85, 2.0
) gm ON gm.course_code = c.course_code
WHERE se.student_id = @student_id
  AND cs.section_code = @section;

-- Verify (expect 10 rows when enlistment is complete)
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
