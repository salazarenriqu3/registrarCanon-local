-- =============================================================================
-- ENROLLMENT REALIGNMENT TEST SEED
--
-- Purpose:
--   Fresh mock data for verifying the enrollment-side term realignment
--   against the live eacdb (4).sql-style baseline currently in use.
--
-- Scenarios covered:
--   1) Current-term subject management should not leak prior-term rows.
--   2) Same-course prior-term history should not block current-term enrollment.
--   3) Existing UOJT vs Capstone schedule conflict remains available for policy review.
--   4) Optional applicant row is available for admission/new-student testing.
--
-- Prereqs:
--   Run against the active shared eacdb database after the registrar current term
--   is already set. This version is aligned to the real dump currently in use,
--   and reuses existing visible students instead of creating synthetic dashboard users.
-- =============================================================================

USE eacdb;

SET FOREIGN_KEY_CHECKS = 0;
SET SQL_SAFE_UPDATES = 0;

-- Resolve the registrar active term and the immediately previous term.
SET @current_raw = (SELECT setting_value FROM system_settings WHERE setting_key = 'CURRENT_ACADEMIC_TERM' LIMIT 1);
SET @current_db = CASE
    WHEN @current_raw LIKE 'SL\_%' AND LENGTH(@current_raw) >= 13 THEN
        CONCAT(SUBSTRING(@current_raw, 4, 1), '1', SUBSTRING(@current_raw, 6, 8))
    ELSE @current_raw
END;
SET @current_term_id = COALESCE(
    (SELECT term_id FROM academic_terms WHERE term_code = @current_raw LIMIT 1),
    (SELECT term_id FROM academic_terms WHERE term_code = @current_db LIMIT 1),
    (SELECT term_id FROM academic_terms WHERE status = 'ACTIVE' OR is_active = 1 ORDER BY term_id DESC LIMIT 1)
);
SET @prior_term_id = COALESCE(
    (SELECT term_id FROM academic_terms WHERE term_id < @current_term_id ORDER BY term_id DESC LIMIT 1),
    @current_term_id
);

-- ---------------------------------------------------------------------------
-- Cleanup from previous runs
-- ---------------------------------------------------------------------------
DELETE FROM student_enlistments
WHERE student_id IN ('2026-9001', '2026-9002')
   OR (student_id IN ('2026-0009', '2026-0011')
       AND course_id IN (SELECT course_id FROM courses WHERE course_code = 'TSTD 42'));

DELETE FROM grades
WHERE student_id IN ('2026-9001', '2026-9002');

DELETE FROM student_ledger
WHERE student_id IN ('2026-9001', '2026-9002');

DELETE FROM students
WHERE student_number IN ('2026-9001', '2026-9002');

DELETE FROM sys_users
WHERE username IN ('2026-9001', '2026-9002');

DELETE sch
FROM class_schedules sch
JOIN class_sections cs ON cs.section_id = sch.section_id
WHERE cs.section_code IN ('BSIT-4-2-TST', 'BSIT-4-2-TST-OLD');

DELETE FROM class_sections
WHERE section_code IN ('BSIT-4-2-TST', 'BSIT-4-2-TST-OLD');

DELETE cc
FROM curriculum_courses cc
JOIN courses c ON c.course_id = cc.course_id
WHERE c.course_code = 'TSTD 42';

DELETE FROM courses
WHERE course_code = 'TSTD 42';

DELETE FROM payments
WHERE reference_number IN ('REALIGN-APP-001', 'REALIGN-APP-002');

DELETE FROM applicants
WHERE reference_number IN ('REALIGN-APP-001', 'REALIGN-APP-002');

-- ---------------------------------------------------------------------------
-- Shared custom course used for duplicate/history tests
-- ---------------------------------------------------------------------------
INSERT INTO courses (
    course_code, course_title, department_id, credit_units,
    lec_units, lab_units, lecture_hours_per_week, lab_hours_per_week,
    course_type, active_status
)
SELECT
    'TSTD 42', 'Term Scope Duplicate Test', p.department_id,
    3, 3, 0, 3, 0,
    'Lecture', 1
FROM programs p
WHERE p.program_code = 'BSIT'
LIMIT 1;

INSERT INTO curriculum_courses (curriculum_id, course_id, year_level, semester_number, is_required)
SELECT ct.curriculum_id, c.course_id, 4, 2, 1
FROM curriculum_templates ct
JOIN programs p ON p.program_id = ct.program_id
JOIN courses c ON c.course_code = 'TSTD 42'
WHERE p.program_code = 'BSIT'
  AND ct.is_active = 1
  AND NOT EXISTS (
      SELECT 1
      FROM curriculum_courses cc
      WHERE cc.curriculum_id = ct.curriculum_id
        AND cc.course_id = c.course_id
        AND cc.year_level = 4
        AND cc.semester_number = 2
  );

INSERT INTO class_sections (course_id, term_id, section_code, max_capacity, section_status, semester_number)
SELECT c.course_id, @current_term_id, 'BSIT-4-2-TST', 30, 'Open', 2
FROM courses c
WHERE c.course_code = 'TSTD 42'
  AND NOT EXISTS (
      SELECT 1
      FROM class_sections cs
      WHERE cs.term_id = @current_term_id
        AND cs.course_id = c.course_id
        AND cs.section_code = 'BSIT-4-2-TST'
  );

INSERT INTO class_sections (course_id, term_id, section_code, max_capacity, section_status, semester_number)
SELECT c.course_id, @prior_term_id, 'BSIT-4-2-TST-OLD', 30, 'Closed', 2
FROM courses c
WHERE c.course_code = 'TSTD 42'
  AND NOT EXISTS (
      SELECT 1
      FROM class_sections cs
      WHERE cs.term_id = @prior_term_id
        AND cs.course_id = c.course_id
        AND cs.section_code = 'BSIT-4-2-TST-OLD'
  );

DELETE sch
FROM class_schedules sch
JOIN class_sections cs ON cs.section_id = sch.section_id
WHERE cs.section_code IN ('BSIT-4-2-TST', 'BSIT-4-2-TST-OLD');

INSERT INTO class_schedules (
    section_id, room_id, faculty_id, day_of_week, start_time, end_time, schedule_type, status
)
SELECT cs.section_id, NULL, NULL, 4, '15:00:00', '16:30:00', 'Lecture', 'OPEN'
FROM class_sections cs
WHERE cs.section_code = 'BSIT-4-2-TST'
  AND cs.term_id = @current_term_id;

INSERT INTO class_schedules (
    section_id, room_id, faculty_id, day_of_week, start_time, end_time, schedule_type, status
)
SELECT cs.section_id, NULL, NULL, 2, '15:00:00', '16:30:00', 'Lecture', 'OPEN'
FROM class_sections cs
WHERE cs.section_code = 'BSIT-4-2-TST-OLD'
  AND cs.term_id = @prior_term_id;

-- ---------------------------------------------------------------------------
-- Optional applicant for the regular auto-enlist path
-- ---------------------------------------------------------------------------
INSERT INTO applicants (
    reference_number, first_name, last_name, middle_name,
    email, mobile, sex, program1, applicant_status,
    application_status, term_year, created_at, updated_at,
    form138_verified, good_moral_verified, psa_birth_cert_verified, id_picture_verified
)
SELECT
    'REALIGN-APP-001', 'Rina', 'Test', 'Garcia',
    'rina.test@example.com', '09170000001', 'Female', 'BSIT',
    'QUALIFIED FOR ENROLLMENT', 'ADMISSION_PENDING',
    @current_raw, NOW(), NOW(),
    1, 1, 1, 1
FROM dual
ON DUPLICATE KEY UPDATE
    first_name = VALUES(first_name),
    last_name = VALUES(last_name),
    middle_name = VALUES(middle_name),
    email = VALUES(email),
    mobile = VALUES(mobile),
    sex = VALUES(sex),
    program1 = VALUES(program1),
    applicant_status = VALUES(applicant_status),
    application_status = VALUES(application_status),
    term_year = VALUES(term_year),
    updated_at = NOW(),
    form138_verified = VALUES(form138_verified),
    good_moral_verified = VALUES(good_moral_verified),
    psa_birth_cert_verified = VALUES(psa_birth_cert_verified),
    id_picture_verified = VALUES(id_picture_verified);

INSERT INTO payments (
    transaction_id, reference_number, amount, payment_method, status, payment_date
) VALUES (
    'PAY-REALIGN-001', 'REALIGN-APP-001', 1000.00, 'Cash (OTC)', 'COMPLETED', NOW()
)
ON DUPLICATE KEY UPDATE
    amount = VALUES(amount),
    payment_method = VALUES(payment_method),
    status = VALUES(status),
    payment_date = VALUES(payment_date);

-- ---------------------------------------------------------------------------
-- Existing student 2026-0009:
--   - already visible in the real dump baseline
--   - current-term subject load should show only current term rows
--   - prior-term history row should NOT appear in current-term subject view
--   - existing UOJT 42 vs UCP2 42 conflict can still be reviewed in the UI
-- ---------------------------------------------------------------------------
INSERT INTO student_enlistments (student_id, course_id, section_id)
SELECT '2026-0009', c.course_id, cs.section_id
FROM courses c
JOIN class_sections cs ON cs.course_id = c.course_id
WHERE c.course_code = 'TSTD 42'
  AND cs.term_id = @prior_term_id
  AND cs.section_code = 'BSIT-4-2-TST-OLD'
  LIMIT 1;

-- ---------------------------------------------------------------------------
-- Existing student 2026-0011:
--   - already visible in the real dump baseline
--   - prior-term duplicate history row for TSTD 42
--   - current-term auto-enlist/manual add should NOT be blocked by prior-term history
-- ---------------------------------------------------------------------------
INSERT INTO student_enlistments (student_id, course_id, section_id)
SELECT '2026-0011', c.course_id, cs.section_id
FROM courses c
JOIN class_sections cs ON cs.course_id = c.course_id
WHERE c.course_code = 'TSTD 42'
  AND cs.term_id = @prior_term_id
  AND cs.section_code = 'BSIT-4-2-TST-OLD'
LIMIT 1;

SET FOREIGN_KEY_CHECKS = 1;
SET SQL_SAFE_UPDATES = 1;

-- ---------------------------------------------------------------------------
-- Quick verification
-- ---------------------------------------------------------------------------
SELECT
    @current_term_id AS current_term_id,
    @prior_term_id AS prior_term_id,
    (SELECT term_code FROM academic_terms WHERE term_id = @current_term_id LIMIT 1) AS current_term_code,
    (SELECT term_code FROM academic_terms WHERE term_id = @prior_term_id LIMIT 1) AS prior_term_code;

SELECT student_number, first_name, last_name, program_code, year_level, semester, term_year
FROM students
WHERE student_number IN ('2026-0009', '2026-0011')
ORDER BY student_number;

SELECT username, role, program_code, year_level, semester, term_year
FROM sys_users
WHERE username IN ('2026-0009', '2026-0011')
ORDER BY username;

SELECT c.course_code, cs.section_code, cs.term_id
FROM class_sections cs
JOIN courses c ON c.course_id = cs.course_id
WHERE c.course_code IN ('TSTD 42', 'UCP2 42', 'UOJT 42')
ORDER BY c.course_code, cs.term_id, cs.section_code;

SELECT se.student_id, c.course_code, cs.section_code, cs.term_id
FROM student_enlistments se
JOIN courses c ON c.course_id = se.course_id
JOIN class_sections cs ON cs.section_id = se.section_id
WHERE se.student_id IN ('2026-0009', '2026-0011')
ORDER BY se.student_id, cs.term_id, c.course_code;
