-- =============================================================================
-- SECOND STUDENT PROFILE + REG FORM HISTORY UAT SEED
--
-- Purpose:
--   Create a second deterministic student profile so the reg-form history
--   report shows more than one real student link during UAT.
--
-- Safe/idempotent:
--   Re-running this script resets only the demo student 26-1-00002.
-- =============================================================================

USE eacdb;
SET NAMES utf8mb4 COLLATE utf8mb4_general_ci;

SET @sn := '26-1-00002';
SET @ref := 'REG-HIST-2026-002';
SET @pwd := '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EhsLkT/Oh.reShMkwpfpJ2';
SET @term_year := (
    SELECT COALESCE(term_year, 'SL2024202511')
    FROM students
    WHERE student_number = '26-1-00001'
    LIMIT 1
);
SET @curriculum_id := (
    SELECT ct.curriculum_id
    FROM curriculum_templates ct
    JOIN programs p ON p.program_id = ct.program_id
    WHERE p.program_code = 'BSIT'
      AND COALESCE(ct.is_active, 0) = 1
    ORDER BY ct.version_number DESC, ct.curriculum_id DESC
    LIMIT 1
);

DELETE FROM student_reg_form_events
WHERE student_number = @sn;

DELETE FROM student_curriculum_assignments
WHERE student_number = @sn;

DELETE FROM student_ledger
WHERE student_id = @sn;

DELETE FROM student_enlistments
WHERE student_id = @sn;

DELETE FROM students
WHERE student_number = @sn;

DELETE FROM sys_users
WHERE username = @sn;

INSERT INTO sys_users (
    username,
    password,
    real_name,
    first_name,
    last_name,
    role,
    program_code,
    year_level,
    semester,
    term_year,
    reference_number,
    student_type,
    enrollment_status_type,
    scholarship_type,
    scholarship_approved,
    scholarship_amount,
    discount_percentage,
    admission_status,
    admission_date,
    enrollment_blocked,
    email,
    mobile,
    is_active,
    status
) VALUES (
    @sn,
    @pwd,
    'Reg History Two',
    'Reg',
    'History',
    'Student',
    'BSIT',
    1,
    1,
    @term_year,
    @ref,
    'New Student',
    'REGULAR',
    'NONE',
    0,
    0.00,
    0.00,
    'ADMITTED',
    NOW(),
    0,
    'reg.history.two@example.com',
    '09170000002',
    1,
    'ACTIVE'
);

INSERT INTO students (
    student_number,
    user_id,
    reference_number,
    first_name,
    last_name,
    middle_name,
    real_name,
    email,
    mobile,
    program_code,
    year_level,
    semester,
    term_year,
    student_type,
    enrollment_status_type,
    admission_status,
    scholarship_type,
    scholarship_approved,
    scholarship_amount,
    discount_percentage,
    section_group,
    status,
    is_active,
    enrollment_blocked,
    password,
    role
)
SELECT
    @sn,
    u.user_id,
    @ref,
    'Reg',
    'History',
    'Two',
    'Reg History Two',
    'reg.history.two@example.com',
    '09170000002',
    'BSIT',
    1,
    1,
    @term_year,
    'New Student',
    'REGULAR',
    'ADMITTED',
    'NONE',
    0,
    0.00,
    0.00,
    NULL,
    'ACTIVE',
    1,
    0,
    NULL,
    'STUDENT'
FROM sys_users u
WHERE u.username = @sn;

INSERT INTO student_curriculum_assignments (
    student_number,
    curriculum_id,
    program_code,
    assignment_type,
    reason,
    is_current
)
VALUES (
    @sn,
    @curriculum_id,
    'BSIT',
    'NEW_ENTRANT',
    'Demo student for reg-form history UAT',
    1
);

INSERT INTO student_reg_form_events (
    student_number,
    event_type,
    purpose,
    related_request_id,
    remarks,
    triggered_by
)
VALUES
(
    @sn,
    'CURRICULUM_ASSIGNED',
    'Registrar curriculum assignment updated',
    NULL,
    'Curriculum assigned for second demo student.',
    'registrar'
),
(
    @sn,
    'SUBJECT_ADD',
    'Registrar subject add completed',
    NULL,
    'Added BSIT demo subject via registrar add flow.',
    'registrar'
),
(
    @sn,
    'OVERPAY_REFUND',
    'Overpayment disposition recorded',
    NULL,
    'Refunded a small demo overpayment amount.',
    'cashier'
),
(
    @sn,
    'PROGRAM_SHIFT',
    'Registrar program shift completed',
    NULL,
    'Demo program shift trail entry for profile testing.',
    'registrar'
);

SELECT student_number, real_name, program_code, year_level, semester, term_year, admission_status
FROM students
WHERE student_number = @sn;

SELECT event_type, purpose, remarks
FROM student_reg_form_events
WHERE student_number = @sn
ORDER BY event_id;
