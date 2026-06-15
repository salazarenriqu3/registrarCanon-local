-- =============================================================================
-- FORMAL WITHDRAWAL UAT SEED
--
-- Purpose:
--   Prepare one predictable enrolled student and one active subject so the
--   Formal Withdrawal workflow can be tested end-to-end:
--     Student Profile request -> Dean review -> Registrar final approval
--     -> subject removed -> formal withdrawal ledger charge/refund logic.
--
-- Safe/idempotent:
--   Re-running this script resets only WDRW-UAT-2026-001 and the dedicated
--   WDRW-UAT-TERM / WDRW-UAT-A demo section.
--
-- Demo student:
--   Student number: WDRW-UAT-2026-001
--   Program: BSCPE
--   Term: SL_1120262026 (maps to academic_terms.term_code 1120262026)
--
-- Manual UAT:
--   1. Restart Registrar after code changes.
--   2. Login admin / 1234.
--   3. Open:
--      http://localhost:8083/registrar/admin/student-manager?username=WDRW-UAT-2026-001
--   4. In Current Enrolled Subjects, choose a withdrawal reason and submit.
--   5. Open Dean queue:
--      http://localhost:8083/registrar/faculty/withdrawals
--      Click Dean Approve.
--   6. Open Registrar queue:
--      http://localhost:8083/registrar/admin/withdrawals
--      Click Registrar Approve.
--   7. Re-open Student Profile and verify the subject is gone.
--   8. Check report:
--      http://localhost:8083/registrar/admin/withdrawals/report
--   9. Optional DB verification at the end of this script shows:
--      - request status
--      - remaining enlistments
--      - formal withdrawal ledger rows
-- =============================================================================

USE eacdb;

SET @student_number := 'WDRW-UAT-2026-001';
SET @reference_number := 'WDRW-UAT-REF-2026-001';
SET @term_code := '1120262026';
SET @term_year := 'SL_1120262026';
SET @section_code := 'WDRW-UAT-A';

-- Keep the policy window open regardless of the historical demo active term.
INSERT INTO academic_terms (
    term_code,
    term_name,
    academic_year,
    semester_number,
    start_date,
    end_date,
    is_active,
    status
) VALUES (
    @term_code,
    'Withdrawal UAT Term',
    '2026-2026',
    1,
    DATE_SUB(CURDATE(), INTERVAL 3 DAY),
    DATE_ADD(CURDATE(), INTERVAL 120 DAY),
    0,
    'INACTIVE'
)
ON DUPLICATE KEY UPDATE
    term_name = VALUES(term_name),
    start_date = VALUES(start_date),
    end_date = VALUES(end_date),
    status = VALUES(status);

SET @term_id := (
    SELECT term_id FROM academic_terms WHERE term_code = @term_code LIMIT 1
);

SET @program_id := (
    SELECT program_id FROM programs WHERE program_code = 'BSCPE' LIMIT 1
);

-- Student Profile assessment requires official fee rows for the student's term.
-- Copy the latest BSCPE Y1/S1 fee row into the dedicated UAT term.
DELETE FROM program_fee_settings
WHERE program_id = @program_id
  AND term_id = @term_id
  AND year_level = 1
  AND semester_number = 1;

INSERT INTO program_fee_settings (
    program_id,
    term_id,
    year_level,
    semester_number,
    fee_tuition_per_unit,
    fee_lec_per_unit,
    fee_lab_per_unit,
    fee_comp_per_unit,
    fee_rle_per_unit,
    fee_misc_registration,
    fee_misc_library,
    fee_misc_medical,
    fee_misc_id,
    fee_misc_athletic,
    fee_misc_guidance,
    fee_misc_lms,
    fee_misc_insurance,
    fee_misc_cultural,
    fee_misc_av,
    fee_misc_energy,
    fee_other_id,
    fee_other_insurance,
    fee_other_comp,
    fee_other_dev,
    fee_other_late_enrollment,
    fee_other_add_drop,
    fee_other_installment,
    is_active
)
SELECT
    program_id,
    @term_id,
    year_level,
    semester_number,
    fee_tuition_per_unit,
    fee_lec_per_unit,
    fee_lab_per_unit,
    fee_comp_per_unit,
    fee_rle_per_unit,
    fee_misc_registration,
    fee_misc_library,
    fee_misc_medical,
    fee_misc_id,
    fee_misc_athletic,
    fee_misc_guidance,
    fee_misc_lms,
    fee_misc_insurance,
    fee_misc_cultural,
    fee_misc_av,
    fee_misc_energy,
    fee_other_id,
    fee_other_insurance,
    fee_other_comp,
    fee_other_dev,
    fee_other_late_enrollment,
    fee_other_add_drop,
    fee_other_installment,
    1
FROM program_fee_settings
WHERE program_id = @program_id
  AND year_level = 1
  AND semester_number = 1
  AND term_id <> @term_id
ORDER BY term_id DESC, fee_setting_id DESC
LIMIT 1;

-- Pick a stable BSCPE subject from the current seeded catalog.
SET @source_section_id := (
    SELECT cs.section_id
    FROM class_sections cs
    JOIN academic_terms at ON at.term_id = cs.term_id
    WHERE cs.section_code LIKE 'BSCPE-1-1%'
    ORDER BY cs.section_id
    LIMIT 1
);

SET @course_id := (
    SELECT course_id FROM class_sections WHERE section_id = @source_section_id LIMIT 1
);

SET @faculty_id := (
    SELECT faculty_id FROM class_sections WHERE section_id = @source_section_id LIMIT 1
);

-- Reset old request/enlistment/demo rows.
DELETE swrl
FROM student_withdrawal_request_lines swrl
JOIN student_withdrawal_requests swr ON swr.request_id = swrl.request_id
WHERE swr.student_number = @student_number;

DELETE FROM student_withdrawal_requests
WHERE student_number = @student_number;

DELETE FROM student_enlistments
WHERE student_id = @student_number;

DELETE FROM student_ledger
WHERE student_id = @student_number;

SET @has_reg_form_events := (
    SELECT COUNT(*)
    FROM information_schema.tables
    WHERE table_schema = DATABASE()
      AND table_name = 'student_reg_form_events'
);
SET @reset_reg_form_events_sql := IF(
    @has_reg_form_events > 0,
    CONCAT('DELETE FROM student_reg_form_events WHERE student_number = ', QUOTE(@student_number)),
    'SELECT 1'
);
PREPARE reset_reg_form_events_stmt FROM @reset_reg_form_events_sql;
EXECUTE reset_reg_form_events_stmt;
DEALLOCATE PREPARE reset_reg_form_events_stmt;

DELETE FROM payments
WHERE reference_number IN (@student_number, @reference_number)
   OR transaction_id LIKE 'WDRW-UAT-%';

DELETE FROM student_curriculum_assignments
WHERE student_number = @student_number;

DELETE FROM students
WHERE student_number = @student_number;

DELETE FROM sys_users
WHERE username = @student_number;

DELETE sch
FROM class_schedules sch
JOIN class_sections cs ON cs.section_id = sch.section_id
WHERE cs.section_code = @section_code
  AND cs.term_id = @term_id;

DELETE FROM class_sections
WHERE section_code = @section_code
  AND term_id = @term_id;

-- Create the dedicated withdrawal UAT section from the source BSCPE subject.
INSERT INTO class_sections (
    course_id,
    term_id,
    section_code,
    faculty_id,
    max_capacity,
    section_status,
    semester_number
) VALUES (
    @course_id,
    @term_id,
    @section_code,
    @faculty_id,
    40,
    'Open',
    1
);

SET @section_id := LAST_INSERT_ID();

INSERT INTO class_schedules (
    section_id,
    room_id,
    faculty_id,
    day_of_week,
    start_time,
    end_time,
    schedule_type,
    status
)
SELECT
    @section_id,
    room_id,
    faculty_id,
    day_of_week,
    start_time,
    end_time,
    schedule_type,
    'OPEN'
FROM class_schedules
WHERE section_id = @source_section_id
LIMIT 2;

-- Fallback schedule if the copied section has no schedule rows.
INSERT INTO class_schedules (
    section_id,
    room_id,
    faculty_id,
    day_of_week,
    start_time,
    end_time,
    schedule_type,
    status
)
SELECT @section_id, NULL, @faculty_id, 1, '08:00:00', '09:30:00', 'Lecture', 'OPEN'
WHERE NOT EXISTS (
    SELECT 1 FROM class_schedules WHERE section_id = @section_id
);

-- Password hash is intentionally not important for this student UAT.
-- Staff use admin / 1234 and prof / 1234 for the workflow.
INSERT INTO sys_users (
    username,
    password,
    real_name,
    first_name,
    last_name,
    middle_name,
    role,
    program_code,
    year_level,
    semester,
    term_year,
    reference_number,
    student_type,
    enrollment_status_type,
    admission_status,
    admission_date,
    email,
    mobile,
    is_active,
    status
) VALUES (
    @student_number,
    '$2a$10$e0NR3OcWjYbG6rN1.00lOOfZG8tCy23fUuDrSiY5zMT6y8Iu1l9Ay',
    'Wendy Withdrawal',
    'Wendy',
    'Withdrawal',
    'Uat',
    'Student',
    'BSCPE',
    1,
    1,
    @term_year,
    @reference_number,
    'New Student',
    'Regular',
    'ENROLLED',
    NOW(),
    'wendy.withdrawal@example.com',
    '09170000001',
    1,
    'ACTIVE'
);

SET @user_id := (
    SELECT user_id FROM sys_users WHERE username = @student_number LIMIT 1
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
    password,
    role,
    status,
    is_active
) VALUES (
    @student_number,
    @user_id,
    @reference_number,
    'Wendy',
    'Withdrawal',
    'Uat',
    'Wendy Withdrawal',
    'wendy.withdrawal@example.com',
    '09170000001',
    'BSCPE',
    1,
    1,
    @term_year,
    'New Student',
    'Regular',
    'ENROLLED',
    '$2a$10$e0NR3OcWjYbG6rN1.00lOOfZG8tCy23fUuDrSiY5zMT6y8Iu1l9Ay',
    'STUDENT',
    'ACTIVE',
    1
);

SET @curriculum_id := (
    SELECT ct.curriculum_id
    FROM curriculum_templates ct
    JOIN programs p ON p.program_id = ct.program_id
    WHERE p.program_code = 'BSCPE'
      AND COALESCE(ct.is_active, 0) = 1
    ORDER BY ct.version_number DESC, ct.curriculum_id DESC
    LIMIT 1
);

INSERT INTO student_curriculum_assignments (
    student_number,
    curriculum_id,
    program_code,
    assignment_type,
    reason,
    is_current
)
SELECT
    @student_number,
    @curriculum_id,
    'BSCPE',
    'UAT',
    'Formal withdrawal UAT seed.',
    1
WHERE @curriculum_id IS NOT NULL;

INSERT INTO student_enlistments (
    student_id,
    course_id,
    section_id,
    enlistment_status,
    enlisted_date
) VALUES (
    @student_number,
    @course_id,
    @section_id,
    'COMMITTED',
    DATE_SUB(NOW(), INTERVAL 8 DAY)
);

-- Give the student a small payment so refund/charge behavior can be observed.
INSERT INTO student_ledger (
    student_id,
    transaction_type,
    description,
    debit,
    credit
) VALUES (
    @student_number,
    'PAYMENT',
    'Withdrawal UAT payment seed',
    0.00,
    8000.00
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
    'WDRW-UAT-PAY-001',
    @student_number,
    8000.00,
    'Cash (OTC)',
    1,
    1,
    @term_year,
    'Formal withdrawal UAT seed payment',
    NOW(),
    'COMPLETED'
);

SELECT
    'READY' AS seed_status,
    @student_number AS student_number,
    @term_code AS term_code,
    @section_id AS section_id,
    @course_id AS course_id,
    (SELECT course_code FROM courses WHERE course_id = @course_id) AS course_code;

SELECT
    'Open Student Profile' AS next_step,
    CONCAT('http://localhost:8083/registrar/admin/student-manager?username=', @student_number) AS url;

SELECT
    se.enlistment_id,
    se.student_id,
    se.section_id,
    cs.section_code,
    c.course_code,
    se.enlistment_status,
    se.enlisted_date
FROM student_enlistments se
JOIN class_sections cs ON cs.section_id = se.section_id
JOIN courses c ON c.course_id = se.course_id
WHERE se.student_id = @student_number;
