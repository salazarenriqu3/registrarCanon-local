-- ======================================================================================
-- EAC REGISTRAR & CASHIER SYSTEM — MEGA DEMONSTRATION DATASET
-- Database: registrar_db_v2
-- Run this AFTER COMPLETE_DATABASE_SETUP.sql to seed demo accounts.
-- ======================================================================================

USE registrar_db_v2;

-- ---------------------------------------------------------
-- 1. CLEANUP — remove demo entries to allow safe re-running
-- ---------------------------------------------------------
SET SQL_SAFE_UPDATES = 0;
DELETE FROM payments               WHERE reference_number IN ('DEMO-001', 'DEMO-002', 'DEMO-003');
DELETE FROM student_ledger         WHERE student_id IN (SELECT user_id FROM sys_users WHERE username LIKE 'DEMO-%');
DELETE FROM jp_student_enlistments WHERE student_id  IN (SELECT id FROM jp_students WHERE student_number LIKE 'DEMO-%');
DELETE FROM jp_students            WHERE student_number LIKE 'DEMO-%';
DELETE FROM eac_applicants         WHERE ref_no = 'EAC-DEMO-ANA';
DELETE FROM eac_application_logs   WHERE ref_no = 'EAC-DEMO-ANA';
DELETE FROM sys_users              WHERE username LIKE 'DEMO-%'
                                      OR username IN ('demo_registrar', 'demo_cashier', 'demo_faculty');
SET SQL_SAFE_UPDATES = 1;

-- ---------------------------------------------------------
-- 2. SYSTEM ACCOUNTS
-- Passwords are stored plain here. The app BCrypt-hashes on first login.
-- ---------------------------------------------------------
INSERT IGNORE INTO sys_users (username, password, real_name, role, is_active) VALUES
('demo_registrar', 'password123', 'Emilio Registrar',      'Registrar', 1),
('demo_cashier',   'password123', 'Cassandra Cashier',     'Admin',     1),
('demo_faculty',   'password123', 'Prof. Juan Dela Cruz',  'Faculty',   1);

-- ---------------------------------------------------------
-- 3. JAYPEE ENGINE SYNC (courses + sections + schedule)
-- ---------------------------------------------------------
INSERT IGNORE INTO jp_programs (program_code, program_name, school_name, category)
VALUES ('BSCS', 'Bachelor of Science in Computer Science', 'EAC', 'College');

INSERT IGNORE INTO jp_courses (course_code, course_title, units, program_code) VALUES
('CS101',   'Introduction to Computing',       3, 'BSCS'),
('CS102',   'Computer Programming 1',          3, 'BSCS'),
('CS103',   'Data Structures and Algorithms',  3, 'BSCS'),
('MATH101', 'Mathematics in the Modern World', 3, 'BSCS');

-- Curriculum mapping: BSCS Year 1 Sem 1 (Year 4 is declared separately so isGraduating logic works correctly)
INSERT IGNORE INTO jp_curriculum_mapping (program_code, course_id, year_level, semester)
SELECT 'BSCS', course_id, 1, 1 FROM jp_courses WHERE course_code IN ('CS101', 'CS102', 'CS103', 'MATH101');

-- Stub mappings for years 2-4 so MAX(year_level)=4 and Year 1 students are NOT flagged graduating
INSERT IGNORE INTO jp_curriculum_mapping (program_code, course_id, year_level, semester)
SELECT 'BSCS', course_id, 2, 1 FROM jp_courses WHERE course_code = 'CS103';
INSERT IGNORE INTO jp_curriculum_mapping (program_code, course_id, year_level, semester)
SELECT 'BSCS', course_id, 3, 1 FROM jp_courses WHERE course_code = 'CS103';
INSERT IGNORE INTO jp_curriculum_mapping (program_code, course_id, year_level, semester)
SELECT 'BSCS', course_id, 4, 1 FROM jp_courses WHERE course_code = 'CS103';

INSERT IGNORE INTO jp_class_sections (course_id, section_name, max_capacity)
SELECT course_id, 'CS-1A', 40 FROM jp_courses
WHERE course_code IN ('CS101', 'CS102', 'CS103', 'MATH101');

-- Schedules for ALL demo subjects (Monday–Thursday, same room for demo simplicity)
INSERT INTO jp_class_schedules (section_id, course_id, day_of_week, start_time, end_time, room, faculty_id)
SELECT s.section_id, c.course_id, 'Monday', '08:00:00', '11:00:00', 'Room 301',
       (SELECT user_id FROM sys_users WHERE username = 'demo_faculty' LIMIT 1)
FROM jp_class_sections s JOIN jp_courses c ON s.course_id = c.course_id
WHERE c.course_code = 'CS101'
  AND NOT EXISTS (SELECT 1 FROM jp_class_schedules x WHERE x.section_id = s.section_id);

INSERT INTO jp_class_schedules (section_id, course_id, day_of_week, start_time, end_time, room, faculty_id)
SELECT s.section_id, c.course_id, 'Tuesday', '08:00:00', '11:00:00', 'Room 302',
       (SELECT user_id FROM sys_users WHERE username = 'demo_faculty' LIMIT 1)
FROM jp_class_sections s JOIN jp_courses c ON s.course_id = c.course_id
WHERE c.course_code = 'CS102'
  AND NOT EXISTS (SELECT 1 FROM jp_class_schedules x WHERE x.section_id = s.section_id);

INSERT INTO jp_class_schedules (section_id, course_id, day_of_week, start_time, end_time, room, faculty_id)
SELECT s.section_id, c.course_id, 'Wednesday', '08:00:00', '11:00:00', 'Room 303',
       (SELECT user_id FROM sys_users WHERE username = 'demo_faculty' LIMIT 1)
FROM jp_class_sections s JOIN jp_courses c ON s.course_id = c.course_id
WHERE c.course_code = 'CS103'
  AND NOT EXISTS (SELECT 1 FROM jp_class_schedules x WHERE x.section_id = s.section_id);

INSERT INTO jp_class_schedules (section_id, course_id, day_of_week, start_time, end_time, room, faculty_id)
SELECT s.section_id, c.course_id, 'Thursday', '13:00:00', '16:00:00', 'Room 304',
       (SELECT user_id FROM sys_users WHERE username = 'demo_faculty' LIMIT 1)
FROM jp_class_sections s JOIN jp_courses c ON s.course_id = c.course_id
WHERE c.course_code = 'MATH101'
  AND NOT EXISTS (SELECT 1 FROM jp_class_schedules x WHERE x.section_id = s.section_id);

-- ---------------------------------------------------------
-- 4. DEMONSTRATION STUDENTS
-- ---------------------------------------------------------

-- -----------------------------------------------
-- A) ANA — Admissions Demo
-- The Admissions UI searches: eac_applicants WHERE status = 'QUALIFIED FOR ENROLLMENT'
-- Search "Ana" or ref_no "EAC-DEMO-ANA" on the Admission Acceptance page
-- -----------------------------------------------
INSERT IGNORE INTO eac_applicants (
    ref_no, applicant_status, term_year,
    first_name, last_name, middle_name, middle_initial, middle_name_na,
    sex, dob, civil_status, nationality, citizenship, age,
    email, email_verified, mobile,
    city, province,
    academic_level, program1, program2,
    form138_verified, good_moral_verified, psa_birth_cert_verified, id_picture_verified,
    created_at
) VALUES (
    'EAC-DEMO-ANA', 'QUALIFIED FOR ENROLLMENT', 'SL_1120252026',
    'Ana', 'Applicant', 'Maria', 'M.', 0,
    'F', '2005-06-15', 'single', 'Filipino', 'Filipino', 20,
    'demo_ana@eac.edu.ph', 1, '09123456789',
    'Manila', 'Metro Manila',
    'College', 'BSCS', 'BSIT',
    1, 1, 1, 1,
    NOW()
);
INSERT IGNORE INTO eac_application_logs (ref_no, action, performed_by, remarks, log_timestamp)
VALUES ('EAC-DEMO-ANA', 'QUALIFIED FOR ENROLLMENT', 'demo_registrar', 'Demo applicant — ready for admission.', NOW());

-- Ana's cashier fee (₱1,000 admission fee — required before Student ID can be generated)
INSERT IGNORE INTO applicant_payments (applicant_id, payment_amount, payment_date, status)
VALUES ('EAC-DEMO-ANA', 1000.00, NOW(), 'UNPROCESSED');

-- -----------------------------------------------
-- B) BEN — Walk-in Payment & Enrollment Trigger Demo
-- Cashier/Ledger search: "Ben" OR "DEMO-001"
-- Has subjects enlisted → assessment will calculate automatically
-- -----------------------------------------------
INSERT IGNORE INTO sys_users (username, password, real_name, role, is_active,
    admission_status, program_code, year_level, semester, term_year,
    scholarship_type, discount_percentage, enrollment_blocked)
VALUES ('DEMO-001', 'password123', 'Ben Admitted', 'Student', 1,
    'ADMITTED', 'BSCS', 1, 1, 'SL_1120252026', 'NONE', 0.00, 0);

INSERT IGNORE INTO jp_students (student_number, first_name, last_name, email, program_code, current_year, status)
VALUES ('DEMO-001', 'Ben', 'Admitted', 'demo_ben@eac.edu.ph', 'BSCS', 1, 'ADMITTED');

-- NOTE: Ben has NO pre-seeded subjects — enroll him LIVE during the demo:
--   Step 1 → Sidebar: Walk-in Payment  → search DEMO-001 → pay ₱3,000 → status becomes ENROLLED
--   Step 2 → Sidebar: Enrollment Hub   → search DEMO-001 → Add subjects one by one

-- -----------------------------------------------
-- C) CARLA — Scholarship Ledger Demo
-- Cashier/Ledger search: "Carla" OR "DEMO-002"
-- DISCOUNT scholar, DP already paid → shows scholarship deduction + partial balance
-- -----------------------------------------------
INSERT IGNORE INTO sys_users (username, password, real_name, role, is_active,
    admission_status, program_code, year_level, semester, term_year,
    scholarship_type, discount_percentage, enrollment_blocked)
VALUES ('DEMO-002', 'password123', 'Carla Scholar', 'Student', 1,
    'ENROLLED', 'BSCS', 1, 1, 'SL_1120252026', 'DISCOUNT', 0.00, 0);

INSERT IGNORE INTO jp_students (student_number, first_name, last_name, email, program_code, current_year, status)
VALUES ('DEMO-002', 'Carla', 'Scholar', 'demo_carla@eac.edu.ph', 'BSCS', 1, 'ENROLLED');

INSERT INTO jp_student_enlistments (student_id, course_id, section_id, status)
SELECT s.id, c.course_id,
       (SELECT section_id FROM jp_class_sections WHERE course_id = c.course_id LIMIT 1),
       'ENROLLED'
FROM jp_students s, jp_courses c
WHERE s.student_number = 'DEMO-002'
  AND c.course_code IN ('CS101', 'CS102', 'MATH101')
  AND NOT EXISTS (
      SELECT 1 FROM jp_student_enlistments e2
      WHERE e2.student_id = s.id AND e2.course_id = c.course_id
  );

-- Carla's downpayment receipt (₱3,000 — already paid, guarded against duplicates)
INSERT IGNORE INTO payments (transaction_id, or_number, reference_number, amount, payment_method,
    semester, year_level, term_year, remarks, payment_date, status)
VALUES ('WLK-DEMO-CARLA', '100200', 'DEMO-002', 3000.00, 'CASH (Over the Counter)',
    1, 1, 'SL_1120252026', 'Downpayment', NOW(), 'COMPLETED');

INSERT INTO student_ledger (student_id, transaction_type, description, credit)
SELECT user_id, 'PAYMENT', 'Walk-in: Downpayment', 3000.00
FROM sys_users WHERE username = 'DEMO-002'
  AND NOT EXISTS (
      SELECT 1 FROM student_ledger sl WHERE sl.student_id = sys_users.user_id AND sl.transaction_type = 'PAYMENT'
  );

-- -----------------------------------------------
-- D) DAVID — Accounting Block Demo
-- Cashier/Ledger search: "David" OR "DEMO-003"
-- Has ₱45,500 forwarded debt → yellow accounting block banner appears instantly
-- -----------------------------------------------
INSERT IGNORE INTO sys_users (username, password, real_name, role, is_active,
    admission_status, program_code, year_level, semester, term_year,
    scholarship_type, discount_percentage, enrollment_blocked)
VALUES ('DEMO-003', 'password123', 'David Debtor', 'Student', 1,
    'ENROLLED', 'BSCS', 2, 1, 'SL_1120252026', 'NONE', 0.00, 0);

INSERT IGNORE INTO jp_students (student_number, first_name, last_name, email, program_code, current_year, status)
VALUES ('DEMO-003', 'David', 'Debtor', 'demo_david@eac.edu.ph', 'BSCS', 2, 'ENROLLED');

-- Historical unpaid balance (triggers accounting block — guarded against duplicates)
INSERT INTO student_ledger (student_id, transaction_type, description, debit, credit)
SELECT user_id, 'ASSESSMENT', '1st Year 1st Semester — Unpaid Balance Carried Forward', 45500.00, 0.00
FROM sys_users WHERE username = 'DEMO-003'
  AND NOT EXISTS (
      SELECT 1 FROM student_ledger sl WHERE sl.student_id = sys_users.user_id AND sl.transaction_type = 'ASSESSMENT'
  );

-- ======================================================================================
-- DONE. Search Guide:
--   Admissions page  → search "Ana" or ref "EAC-DEMO-ANA"
--   Cashier / Ledger → search "DEMO-001" or "Ben"
--                    → search "DEMO-002" or "Carla"
--                    → search "DEMO-003" or "David"
-- ======================================================================================
