-- =============================================================================
-- Audit/Fix — Elon Musk 2026-0002 term alignment
--
-- Problem this fixes:
--   Elon is Y2/S1, but if term_year is SL_1120252026, Enrollment parses it as
--   Year 1 / Semester 1 and prices him using Y1/S1 fees.
--
-- Correct Y2/S1 A.Y. 2025-2026 student term code:
--   SL_1220252026
--
-- Safe to run for this demo student. It does not delete enrollments, ledger,
-- payments, grades, or fee rows.
-- =============================================================================
USE eacdb;

SET @student_id = '2026-0002';
SET @expected_term_year = 'SL_1220252026';

-- Before
SELECT 'BEFORE sys_users' AS src,
       username, program_code, year_level, semester, term_year, admission_status, student_type
FROM sys_users
WHERE username = @student_id;

SELECT 'BEFORE students' AS src,
       student_number, program_code, year_level, semester, term_year, admission_status, student_type
FROM students
WHERE student_number = @student_id;

-- Fix only the standing code. Y2/S1 should encode the student year level as the
-- second digit after SL_: SL_1 2 20252026.
UPDATE sys_users
SET year_level = 2,
    semester = 1,
    term_year = @expected_term_year,
    student_type = 'Continuing'
WHERE username = @student_id;

UPDATE students
SET year_level = 2,
    semester = 1,
    term_year = @expected_term_year,
    student_type = 'Continuing'
WHERE student_number = @student_id;

-- After
SELECT 'AFTER sys_users' AS src,
       username, program_code, year_level, semester, term_year, admission_status, student_type
FROM sys_users
WHERE username = @student_id;

SELECT 'AFTER students' AS src,
       student_number, program_code, year_level, semester, term_year, admission_status, student_type
FROM students
WHERE student_number = @student_id;

-- Confirm exact Y2/S1 fee row that Enrollment and Registrar should now use.
SELECT p.program_code,
       at.term_code,
       pgf.year_level,
       pgf.semester_number,
       pgf.tuition_per_unit
FROM program_general_fees pgf
JOIN programs p ON p.program_id = pgf.program_id
LEFT JOIN academic_terms at ON at.term_id = pgf.term_id
WHERE p.program_code = 'BSIT'
  AND at.term_code = '1120252026'
  AND pgf.year_level = 2
  AND pgf.semester_number = 1
  AND pgf.is_active = 1;

-- Confirm current Y2/S1 enlisted load. This shows the existing current data;
-- it does not modify subjects.
SELECT cs.section_code,
       at.term_code,
       c.course_code,
       c.course_title,
       c.credit_units
FROM student_enlistments se
JOIN class_sections cs ON cs.section_id = se.section_id
JOIN courses c ON c.course_id = se.course_id
LEFT JOIN academic_terms at ON at.term_id = cs.term_id
WHERE se.student_id = @student_id
  AND cs.section_code = 'BSIT-2-1-A'
ORDER BY c.course_code;

SELECT COUNT(*) AS y2s1_subjects,
       COALESCE(SUM(c.credit_units), 0) AS y2s1_units
FROM student_enlistments se
JOIN class_sections cs ON cs.section_id = se.section_id
JOIN courses c ON c.course_id = se.course_id
WHERE se.student_id = @student_id
  AND cs.section_code = 'BSIT-2-1-A';
