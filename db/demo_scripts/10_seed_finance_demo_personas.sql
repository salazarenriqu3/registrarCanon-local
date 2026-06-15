-- =============================================================================
-- FINANCE DEMO PERSONAS — fresh seed for Jun 2026 billing QA
-- Run AFTER: 00_fresh_demo_bootstrap + 00_bsit_full_align + seed_program_fees
-- Run AFTER: 00_finance_demo_reset.sql
-- Password (all): 1234
--
-- Personas:
--   2026-0028 Juan Dela Cruz  — Student Manager add/drop, clean current term
--   2026-0027 John Doe        — forward PHP 100, pay PHP 1 → net PHP 99
--   2026-0026 Jane TermTest    — Y1 S2 unpaid balance before term transition
-- =============================================================================
USE eacdb;
SET NAMES utf8mb4 COLLATE utf8mb4_general_ci;

SET @pwd = '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EhsLkT/Oh.reShMkwpfpJ2';

-- ── Open registrar term: A.Y. 2025-2026 2nd Sem (Y2 S2 demo window) ─────────
SET @open_db  = '2120252026';
SET @open_sl  = 'SL_2220252026';
SET @open_tid = (SELECT term_id FROM academic_terms WHERE term_code = @open_db LIMIT 1);

UPDATE academic_terms SET is_active = 0, status = 'INACTIVE';
UPDATE academic_terms SET is_active = 1, status = 'ACTIVE' WHERE term_code = @open_db;
UPDATE system_settings SET setting_value = @open_db WHERE setting_key = 'CURRENT_ACADEMIC_TERM';

-- Pick one Y2 S2 BSIT block section (first curriculum course on BSIT-2-2-A)
SET @sec_y2s2 = (
    SELECT cs.section_id
    FROM class_sections cs
    JOIN courses c ON c.course_id = cs.course_id
    JOIN curriculum_courses cc ON cc.course_id = c.course_id
    JOIN curriculum_templates ct ON ct.curriculum_id = cc.curriculum_id AND ct.is_active = 1
    JOIN programs p ON p.program_id = ct.program_id
    WHERE p.program_code = 'BSIT'
      AND cs.term_id = @open_tid
      AND cs.section_code = 'BSIT-2-2-A'
      AND cc.year_level = 2 AND cc.semester_number = 2
    ORDER BY c.course_code
    LIMIT 1
);

-- ── Helper: Juan & John (Y2 S2, ENROLLED, 1 subject) ─────────────────────────
-- 2026-0028 Juan Dela Cruz
SET @sn = '2026-0028';
INSERT INTO applicants (reference_number, first_name, last_name, email, program1, applicant_status, term_year, created_at, updated_at)
VALUES ('DEMO-FIN-0028', 'Juan', 'Dela Cruz', 'juan.delacruz@example.com', 'BSIT', 'ENROLLED', @open_sl, NOW(), NOW());
INSERT INTO sys_users (username, password, real_name, first_name, last_name, role, program_code, year_level, semester, term_year,
    reference_number, student_type, admission_status, is_active, status)
VALUES (@sn, @pwd, 'Juan Dela Cruz', 'Juan', 'Dela Cruz', 'Student', 'BSIT', 2, 2, @open_sl,
    'DEMO-FIN-0028', 'Continuing', 'ENROLLED', 1, 'ACTIVE');
INSERT INTO students (student_number, user_id, reference_number, first_name, last_name, real_name, email, program_code,
    year_level, semester, term_year, student_type, admission_status, scholarship_type, scholarship_approved, is_active, enrollment_blocked, status, role)
SELECT @sn, user_id, 'DEMO-FIN-0028', 'Juan', 'Dela Cruz', 'Juan Dela Cruz', 'juan.delacruz@example.com', 'BSIT',
    2, 2, @open_sl, 'Continuing', 'ENROLLED', 'NONE', 0, 1, 0, 'ACTIVE', 'STUDENT'
FROM sys_users WHERE username = @sn;
INSERT INTO student_enlistments (student_id, course_id, section_id)
SELECT @sn, cs.course_id, cs.section_id FROM class_sections cs WHERE cs.section_id = @sec_y2s2;

-- 2026-0027 John Doe (+ PHP 100 forward debt)
SET @sn = '2026-0027';
INSERT INTO applicants (reference_number, first_name, last_name, email, program1, applicant_status, term_year, created_at, updated_at)
VALUES ('DEMO-FIN-0027', 'John', 'Doe', 'john.doe@example.com', 'BSIT', 'ENROLLED', @open_sl, NOW(), NOW());
INSERT INTO sys_users (username, password, real_name, first_name, last_name, role, program_code, year_level, semester, term_year,
    reference_number, student_type, admission_status, is_active, status)
VALUES (@sn, @pwd, 'John Doe', 'John', 'Doe', 'Student', 'BSIT', 2, 2, @open_sl,
    'DEMO-FIN-0027', 'Continuing', 'ENROLLED', 1, 'ACTIVE');
INSERT INTO students (student_number, user_id, reference_number, first_name, last_name, real_name, email, program_code,
    year_level, semester, term_year, student_type, admission_status, scholarship_type, scholarship_approved, is_active, enrollment_blocked, status, role)
SELECT @sn, user_id, 'DEMO-FIN-0027', 'John', 'Doe', 'John Doe', 'john.doe@example.com', 'BSIT',
    2, 2, @open_sl, 'Continuing', 'ENROLLED', 'NONE', 0, 1, 0, 'ACTIVE', 'STUDENT'
FROM sys_users WHERE username = @sn;
INSERT INTO student_enlistments (student_id, course_id, section_id)
SELECT @sn, cs.course_id, cs.section_id FROM class_sections cs WHERE cs.section_id = @sec_y2s2;
INSERT INTO student_ledger (student_id, transaction_type, description, debit, credit)
VALUES (@sn, 'FORWARDED_BALANCE', 'Balance forwarded from previous term (demo seed)', 100.00, 0);

-- ── 2026-0026 Jane TermTest — Y1 S2 before term transition ───────────────────
SET @y1s2_db  = '2120242025';
SET @y1s2_sl  = 'SL_2120242025';
SET @y1s2_tid = (SELECT term_id FROM academic_terms WHERE term_code = @y1s2_db LIMIT 1);
SET @sec_y1s2 = (
    SELECT cs.section_id FROM class_sections cs
    JOIN curriculum_courses cc ON cc.course_id = cs.course_id
    JOIN curriculum_templates ct ON ct.curriculum_id = cc.curriculum_id AND ct.is_active = 1
    JOIN programs p ON p.program_id = ct.program_id
    WHERE p.program_code = 'BSIT' AND cs.term_id = @y1s2_tid AND cs.section_code = 'BSIT-1-2-A'
      AND cc.year_level = 1 AND cc.semester_number = 2
    ORDER BY cs.section_id LIMIT 1
);

SET @sn = '2026-0026';
INSERT INTO applicants (reference_number, first_name, last_name, email, program1, applicant_status, term_year, created_at, updated_at)
VALUES ('DEMO-FIN-0026', 'Jane', 'TermTest', 'jane.termtest@example.com', 'BSIT', 'ENROLLED', @y1s2_sl, NOW(), NOW());
INSERT INTO sys_users (username, password, real_name, first_name, last_name, role, program_code, year_level, semester, term_year,
    reference_number, student_type, admission_status, is_active, status)
VALUES (@sn, @pwd, 'Jane TermTest', 'Jane', 'TermTest', 'Student', 'BSIT', 1, 2, @y1s2_sl,
    'DEMO-FIN-0026', 'Regular', 'ENROLLED', 1, 'ACTIVE');
INSERT INTO students (student_number, user_id, reference_number, first_name, last_name, real_name, email, program_code,
    year_level, semester, term_year, student_type, admission_status, scholarship_type, scholarship_approved, is_active, enrollment_blocked, status, role)
SELECT @sn, user_id, 'DEMO-FIN-0026', 'Jane', 'TermTest', 'Jane TermTest', 'jane.termtest@example.com', 'BSIT',
    1, 2, @y1s2_sl, 'Regular', 'ENROLLED', 'NONE', 0, 1, 0, 'ACTIVE', 'STUDENT'
FROM sys_users WHERE username = @sn;
INSERT INTO student_enlistments (student_id, course_id, section_id)
SELECT @sn, cs.course_id, cs.section_id FROM class_sections cs WHERE cs.section_id = @sec_y1s2;

-- Y1 S2 assessment (matches demo scenario: total 56074, paid 3000 → forward debt 53074)
INSERT INTO student_ledger (student_id, transaction_type, description, debit, credit) VALUES
(@sn, 'TUITION_ASSESSMENT', 'Tuition Fee Assessment (demo Y1 S2 block)', 30000.00, 0),
(@sn, 'MISC_ASSESSMENT',    'Miscellaneous Fees', 8952.00, 0),
(@sn, 'OTHER_ASSESSMENT',   'Other Fees', 17122.00, 0);

INSERT INTO payments (transaction_id, or_number, reference_number, amount, payment_method, semester, year_level, term_year, remarks, payment_date, status)
VALUES ('DEMO-0026-DP', 'OR-0026-01', @sn, 3000.00, 'CASH', 2, 1, @y1s2_sl, 'Demo Y1 S2 partial payment', NOW(), 'COMPLETED');
INSERT INTO student_ledger (student_id, transaction_type, description, debit, credit)
VALUES (@sn, 'PAYMENT', 'Demo Y1 S2 partial payment', 0, 3000.00);

-- ── Summary ───────────────────────────────────────────────────────────────────
SELECT student_number, real_name, year_level, semester, term_year, admission_status
FROM students
WHERE student_number IN ('2026-0026','2026-0027','2026-0028')
ORDER BY student_number;

SELECT student_id,
       COALESCE(SUM(debit),0) - COALESCE(SUM(credit),0) AS net_forwarded
FROM student_ledger
WHERE student_id IN ('2026-0026','2026-0027','2026-0028')
  AND transaction_type = 'FORWARDED_BALANCE'
GROUP BY student_id;

SELECT 'Open term' AS label, setting_value AS current_db_term
FROM system_settings WHERE setting_key = 'CURRENT_ACADEMIC_TERM';
