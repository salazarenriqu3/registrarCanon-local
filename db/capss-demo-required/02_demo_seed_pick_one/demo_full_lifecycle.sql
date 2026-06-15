-- ============================================================
-- demo_full_lifecycle.sql
-- Full 4-year BSIT demo student: Maria Santos (2026-1001)
-- Run AFTER:
--   0) db/fix
--   1) ../01_setup/01_fresh_demo_bootstrap.sql
--   2) ../01_setup/02_bsit_full_align_term_and_curriculum.sql
--   3) ../01_setup/03_seed_program_fees_full_lifecycle.sql
-- Use 00_demo_applicant_setup.sql (this folder) for live admission flow.
-- Grades: ../03_grades_maria/01-08 during panel demo.
-- ============================================================
USE eacdb;
SET FOREIGN_KEY_CHECKS = 0;
SET SQL_SAFE_UPDATES   = 0;

-- 1. Applicant record
INSERT IGNORE INTO applicants (
    reference_number, first_name, last_name, middle_name,
    email, mobile, sex, program1, applicant_status,
    application_status, term_year, created_at, updated_at,
    form138_verified, good_moral_verified, psa_birth_cert_verified, id_picture_verified
) VALUES (
    'DEMO-SANTOS-001', 'Maria', 'Santos', 'Reyes',
    'maria.santos@demo.eac.edu.ph', '09171234567', 'Female', 'BSIT',
    'QUALIFIED FOR ENROLLMENT', 'ADMISSION_PENDING',
    'SL_1120242025', NOW(), NOW(), 1, 1, 1, 1
);

-- 2. Admission payment (₱1,000 downpayment)
INSERT IGNORE INTO payments (
    transaction_id, reference_number, amount, payment_method, status, payment_date
) VALUES (
    'PAY-DEMO-SANTOS-001', 'DEMO-SANTOS-001', 1000.00, 'Cash (OTC)', 'COMPLETED', NOW()
);

-- 3. sys_users account
INSERT IGNORE INTO sys_users (
    username, password, real_name, first_name, last_name, middle_name,
    role, program_code, year_level, semester, term_year, reference_number,
    student_type, enrollment_status_type, admission_status, is_active, status
) VALUES (
    '2026-1001', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EhsLkT/Oh.reShMkwpfpJ2', -- pw: 1234
    'Maria Reyes Santos', 'Maria', 'Santos', 'Reyes',
    'Student', 'BSIT', 1, 1, 'SL_1120242025', 'DEMO-SANTOS-001',
    'Regular', 'Regular', 'ENROLLED', 1, 'ACTIVE'
);

-- 4. students table entry
INSERT IGNORE INTO students (
    student_number, user_id, reference_number,
    first_name, last_name, middle_name, real_name,
    email, mobile, program_code,
    year_level, semester, term_year,
    student_type, admission_status,
    scholarship_type, scholarship_approved, scholarship_amount,
    discount_percentage, is_active, enrollment_blocked,
    status, role
) SELECT
    '2026-1001', user_id, 'DEMO-SANTOS-001',
    'Maria', 'Santos', 'Reyes', 'Maria Reyes Santos',
    'maria.santos@demo.eac.edu.ph', '09171234567', 'BSIT',
    1, 1, 'SL_1120242025',
    'Regular', 'ENROLLED',
    'NONE', 0, 0.00,
    0.00, 1, 0,
    'ACTIVE', 'STUDENT'
FROM sys_users WHERE username = '2026-1001';

-- 5. Student ledger: initial payment
INSERT IGNORE INTO student_ledger (student_id, transaction_type, description, credit)
VALUES ('2026-1001', 'PAYMENT', 'Tuition Fee - Admission', 1000.00);

-- 6. Grades are modularized into:
--    db/capss-demo-required/03_grades_maria/01_demo_grades_y1s1.sql through 08_demo_grades_y4s2.sql
--    (run them term-by-term during the demo)

-- 7. Open enrollment window (required for self-service demo)
INSERT IGNORE INTO system_settings (setting_key, setting_value) VALUES ('enrollment_open', 'true');
UPDATE system_settings SET setting_value = 'true' WHERE setting_key = 'enrollment_open';

SET FOREIGN_KEY_CHECKS = 1;
SET SQL_SAFE_UPDATES   = 1;

-- Verify
SELECT student_number, first_name, last_name, program_code, year_level, semester, admission_status
FROM students WHERE student_number = '2026-1001';

-- (Grades will be empty until you run 01_demo_grades_y1s1.sql, etc.)
SELECT
  g.student_id, c.course_code, c.course_title, g.prelim, g.midterm, g.final_grade, g.semestral_grade, g.remarks
FROM grades g
JOIN courses c ON g.course_id = c.course_id
WHERE g.student_id = '2026-1001'
ORDER BY g.date_recorded, c.course_code;

