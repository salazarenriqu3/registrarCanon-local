-- =============================================================================
-- Fresh demo student: Elon Musk 2026-0004 (BSIT Y1 — start at Y1S1)
-- Run AFTER: capss-demo-required/01_setup/01_fresh_demo_bootstrap.sql + 00_bsit_full_align + seed_program_fees
-- Password (sys_users): 1234
-- After seed: use Enrollment Cashier only for payments (writes payments + ledger).
-- =============================================================================
USE eacdb;

SET @sn = '2026-0004';
SET @sl_y1s1 = 'SL_1120242025';

DELETE FROM grades WHERE student_id = @sn;
DELETE FROM student_enlistments WHERE student_id = @sn;
DELETE FROM student_ledger WHERE student_id = @sn;
DELETE FROM payments WHERE reference_number = @sn;
DELETE FROM students WHERE student_number = @sn;
DELETE FROM sys_users WHERE username = @sn;
DELETE FROM applicants WHERE reference_number IN ('DEMO-ELON-001', @sn);

INSERT INTO applicants (
    reference_number, first_name, last_name, email, mobile, sex, program1,
    applicant_status, application_status, term_year, created_at, updated_at,
    form138_verified, good_moral_verified, psa_birth_cert_verified, id_picture_verified
) VALUES (
    'DEMO-ELON-001', 'Elon', 'Musk', 'elon.musk@demo.eac.edu.ph', '09170000004', 'Male', 'BSIT',
    'QUALIFIED FOR ENROLLMENT', 'ADMISSION_PENDING', @sl_y1s1, NOW(), NOW(),
    1, 1, 1, 1
);

INSERT INTO sys_users (
    username, password, real_name, first_name, last_name,
    role, program_code, year_level, semester, term_year, reference_number,
    student_type, enrollment_status_type, admission_status, is_active, status
) VALUES (
    @sn, '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EhsLkT/Oh.reShMkwpfpJ2',
    'Elon Musk', 'Elon', 'Musk',
    'Student', 'BSIT', 1, 1, @sl_y1s1, 'DEMO-ELON-001',
    'Regular', 'Regular', 'ADMITTED', 1, 'ACTIVE'
);

INSERT INTO students (
    student_number, user_id, reference_number,
    first_name, last_name, real_name, email, mobile, program_code,
    year_level, semester, term_year, student_type, admission_status,
    scholarship_type, scholarship_approved, is_active, enrollment_blocked, status, role
)
SELECT @sn, user_id, 'DEMO-ELON-001',
    'Elon', 'Musk', 'Elon Musk', 'elon.musk@demo.eac.edu.ph', '09170000004', 'BSIT',
    1, 1, @sl_y1s1, 'Regular', 'ADMITTED',
    'NONE', 0, 1, 0, 'ACTIVE', 'STUDENT'
FROM sys_users WHERE username = @sn;

UPDATE system_settings SET setting_value = @sl_y1s1 WHERE setting_key = 'CURRENT_ACADEMIC_TERM';

SELECT student_number, program_code, year_level, semester, term_year, admission_status
FROM students WHERE student_number = @sn;
