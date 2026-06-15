-- =============================================================================
-- IRREGULAR ADMISSION ALIGNMENT TEST SEED
--
-- Purpose:
--   Create one clean transferee / irregular applicant that can be used to test
--   the registrar-owned pre-registration snapshot flow before full enrollment
--   integration is changed.
--
-- Result:
--   Applicant ref: IRREG-TEST-2026-001
--   Expected behavior:
--     1) Appears in Registrar Admission Processing search
--     2) Is detected as irregular because prior-school fields are filled
--     3) Cannot be admitted as Year 2+ until registrar subject lines exist
--     4) Can be completed after snapshot header + subject line(s) are saved
-- =============================================================================

USE eacdb;

SET @current_raw = (
    SELECT setting_value
    FROM system_settings
    WHERE setting_key = 'CURRENT_ACADEMIC_TERM'
    LIMIT 1
);

DELETE FROM student_enlistments
WHERE student_id IN (
    SELECT student_number FROM students WHERE reference_number = 'IRREG-TEST-2026-001'
);

DELETE FROM student_ledger
WHERE student_id IN (
    SELECT student_number FROM students WHERE reference_number = 'IRREG-TEST-2026-001'
);

DELETE FROM student_curriculum_assignments
WHERE student_number IN (
    SELECT student_number FROM students WHERE reference_number = 'IRREG-TEST-2026-001'
);

DELETE FROM grades
WHERE student_id IN (
    SELECT student_number FROM students WHERE reference_number = 'IRREG-TEST-2026-001'
);

DELETE FROM students
WHERE reference_number = 'IRREG-TEST-2026-001';

DELETE FROM sys_users
WHERE reference_number = 'IRREG-TEST-2026-001';

DELETE FROM applicant_pre_reg_subject_lines
WHERE reference_number = 'IRREG-TEST-2026-001';

DELETE FROM applicant_pre_reg_snapshots
WHERE reference_number = 'IRREG-TEST-2026-001';

DELETE FROM payments
WHERE reference_number = 'IRREG-TEST-2026-001';

DELETE FROM applicants
WHERE reference_number = 'IRREG-TEST-2026-001';

INSERT INTO applicants (
    reference_number,
    first_name,
    last_name,
    middle_name,
    email,
    mobile,
    sex,
    program1,
    program2,
    applicant_status,
    application_status,
    term_year,
    year_level,
    semester,
    last_school,
    last_school_year,
    course_taken,
    form138_verified,
    good_moral_verified,
    psa_birth_cert_verified,
    id_picture_verified,
    created_at,
    updated_at
) VALUES (
    'IRREG-TEST-2026-001',
    'Irene',
    'Transferee',
    'Lopez',
    'irene.transferee@example.com',
    '09171234567',
    'Female',
    'BSIT',
    'BSCS',
    'QUALIFIED FOR ENROLLMENT',
    'ADMISSION_PENDING',
    @current_raw,
    2,
    1,
    'Sample Prior College',
    '2024',
    'BS Information Technology',
    1,
    1,
    1,
    1,
    NOW(),
    NOW()
);

INSERT INTO payments (
    transaction_id,
    reference_number,
    amount,
    payment_method,
    semester,
    year_level,
    term_year,
    remarks,
    payment_date,
    status
) VALUES (
    'PAY-IRREG-TEST-2026-001',
    'IRREG-TEST-2026-001',
    1000.00,
    'Cash (OTC)',
    1,
    2,
    @current_raw,
    'Irregular alignment test seed payment',
    NOW(),
    'COMPLETED'
);

SELECT reference_number, first_name, last_name, program1, last_school, course_taken, applicant_status
FROM applicants
WHERE reference_number = 'IRREG-TEST-2026-001';

SELECT reference_number, amount, status, term_year
FROM payments
WHERE reference_number = 'IRREG-TEST-2026-001';
