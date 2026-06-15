-- ============================================================
-- EAC REGISTRAR — GRADING TEST DATASET
-- Run this against: registrar_db_v2
-- Purpose: Populate faculty, courses, class_schedules, and
--          student_grades so the grading UI can be tested end-to-end.
-- ============================================================

SET SQL_SAFE_UPDATES = 0;

-- ============================================================
-- STEP 1: FACULTY ACCOUNTS
-- All passwords are '1234' (BCrypt hash generated at startup via ensureUserPassword)
-- We'll just update/keep the existing 'prof' account and add two more faculty.
-- ============================================================
INSERT IGNORE INTO sys_users (username, password, real_name, role, is_active)
VALUES
  ('prof',   '$2a$10$PLACEHOLDER', 'Dr. Maria Santos',   'Faculty', 1),
  ('prof2',  '$2a$10$PLACEHOLDER', 'Prof. Jose Dela Cruz', 'Faculty', 1),
  ('prof3',  '$2a$10$PLACEHOLDER', 'Prof. Lena Aquino',  'Faculty', 1);

-- Fix: Set actual BCrypt hash after the app resets them on next startup.
-- The app's ensureUserPassword only handles 'prof', so for prof2 and prof3,
-- reset via the admin panel or run this after the app sets the hash:
UPDATE sys_users SET real_name = 'Dr. Maria Santos' WHERE username = 'prof';


-- ============================================================
-- STEP 2: COURSE CATALOG (legacy grading tables)
-- ============================================================
INSERT IGNORE INTO curriculum_catalog (course_code, description, units) VALUES
  ('CC101',  'Introduction to Computing',          3),
  ('CC102',  'Computer Programming 1',             3),
  ('CC103',  'Computer Programming 2',             3),
  ('MATH101','Mathematics in the Modern World',    3),
  ('NSTP101','National Service Training Program',  3),
  ('PE101',  'Physical Education 1',               2),
  ('ENGL101','Purposive Communication',            3),
  ('SCI101', 'Natural Science',                    3);


-- ============================================================
-- STEP 3: ASSIGNED CLASSES (linked to faculty)
-- Replace PROF_ID below with the actual user_id of 'prof'.
-- We use a subquery so it auto-resolves.
-- ============================================================
INSERT INTO class_schedules (course_code, section, faculty_id, day_of_week, start_time, end_time, status)
VALUES
  ('CC101',  'BSCS-1A', (SELECT user_id FROM sys_users WHERE username = 'prof'  LIMIT 1), 'Monday-Wednesday',    700,  900,  'OPEN'),
  ('CC102',  'BSCS-1A', (SELECT user_id FROM sys_users WHERE username = 'prof'  LIMIT 1), 'Tuesday-Thursday',    900,  1200, 'OPEN'),
  ('CC103',  'BSIT-1A', (SELECT user_id FROM sys_users WHERE username = 'prof'  LIMIT 1), 'Friday',              1300, 1600, 'OPEN'),
  ('MATH101','BSCS-1A', (SELECT user_id FROM sys_users WHERE username = 'prof2' LIMIT 1), 'Monday-Wednesday',    1300, 1500, 'OPEN'),
  ('ENGL101','BSCS-1A', (SELECT user_id FROM sys_users WHERE username = 'prof2' LIMIT 1), 'Tuesday-Thursday',    700,  900,  'OPEN'),
  ('SCI101', 'BSIT-1A', (SELECT user_id FROM sys_users WHERE username = 'prof3' LIMIT 1), 'Monday',              900,  1200, 'OPEN'),
  ('PE101',  'BSCS-1A', (SELECT user_id FROM sys_users WHERE username = 'prof3' LIMIT 1), 'Friday',              700,  900,  'OPEN');


-- ============================================================
-- STEP 4: STUDENT GRADE ENTRIES
-- Linked to schedule_id (auto-generated). We use a subquery per schedule.
-- We reference real sys_users student IDs where possible.
-- ============================================================

-- Helper: Get schedule IDs
-- CC101 BSCS-1A (prof)
INSERT INTO student_grades (schedule_id, student_name, student_id, status)
SELECT s.schedule_id, u.real_name, u.user_id, 'DRAFT'
FROM class_schedules s
CROSS JOIN sys_users u
WHERE s.course_code = 'CC101' AND s.section = 'BSCS-1A'
  AND u.role = 'Student'
ON DUPLICATE KEY UPDATE student_name = u.real_name;

-- CC102 BSCS-1A (prof)
INSERT INTO student_grades (schedule_id, student_name, student_id, status)
SELECT s.schedule_id, u.real_name, u.user_id, 'DRAFT'
FROM class_schedules s
CROSS JOIN sys_users u
WHERE s.course_code = 'CC102' AND s.section = 'BSCS-1A'
  AND u.role = 'Student'
ON DUPLICATE KEY UPDATE student_name = u.real_name;

-- CC103 BSIT-1A (prof)
INSERT INTO student_grades (schedule_id, student_name, student_id, status)
SELECT s.schedule_id, u.real_name, u.user_id, 'DRAFT'
FROM class_schedules s
CROSS JOIN sys_users u
WHERE s.course_code = 'CC103' AND s.section = 'BSIT-1A'
  AND u.role = 'Student'
ON DUPLICATE KEY UPDATE student_name = u.real_name;

-- MATH101 BSCS-1A (prof2)
INSERT INTO student_grades (schedule_id, student_name, student_id, status)
SELECT s.schedule_id, u.real_name, u.user_id, 'DRAFT'
FROM class_schedules s
CROSS JOIN sys_users u
WHERE s.course_code = 'MATH101' AND s.section = 'BSCS-1A'
  AND u.role = 'Student'
ON DUPLICATE KEY UPDATE student_name = u.real_name;

-- ENGL101 BSCS-1A (prof2)
INSERT INTO student_grades (schedule_id, student_name, student_id, status)
SELECT s.schedule_id, u.real_name, u.user_id, 'DRAFT'
FROM class_schedules s
CROSS JOIN sys_users u
WHERE s.course_code = 'ENGL101' AND s.section = 'BSCS-1A'
  AND u.role = 'Student'
ON DUPLICATE KEY UPDATE student_name = u.real_name;


-- ============================================================
-- STEP 5: PRE-FILL SOME GRADES (optional, for testing UI display)
-- Grade entries: prelim/midterm/final are raw percentage scores (0-100)
-- The Java app converts them to point grades on the fly
-- ============================================================

-- Set some grades for the first class schedule (CC101, BSCS-1A)
UPDATE student_grades sg
JOIN class_schedules cs ON sg.schedule_id = cs.schedule_id
SET sg.prelim = 88, sg.midterm = 92, sg.`final` = 0,
    sg.semestral_grade = 0, sg.remarks = 'Ongoing'
WHERE cs.course_code = 'CC101' AND cs.section = 'BSCS-1A'
AND LOWER(sg.student_name) LIKE '%clarissa%';

UPDATE student_grades sg
JOIN class_schedules cs ON sg.schedule_id = cs.schedule_id
SET sg.prelim = 75, sg.midterm = 80, sg.`final` = 0,
    sg.semestral_grade = 0, sg.remarks = 'Ongoing'
WHERE cs.course_code = 'CC101' AND cs.section = 'BSCS-1A'
AND LOWER(sg.student_name) LIKE '%maron%';


-- ============================================================
-- STEP 6: GRADING WINDOWS — make all periods OPEN for testing
-- ============================================================
UPDATE system_settings SET setting_value = 'FORCE_OPEN' WHERE setting_key = 'PRELIM_OVERRIDE';
UPDATE system_settings SET setting_value = 'FORCE_OPEN' WHERE setting_key = 'MIDTERM_OVERRIDE';
UPDATE system_settings SET setting_value = 'FORCE_OPEN' WHERE setting_key = 'FINAL_OVERRIDE';


-- ============================================================
-- DONE. Summary:
--   → 8 subjects added to curriculum_catalog
--   → 7 class sections created and assigned to prof/prof2/prof3
--   → Students auto-enrolled into grade sheets via subquery
--   → Clarissa + Maron have partial prelim/midterm grades in CC101
--   → All grading windows set to FORCE_OPEN
-- Login as 'prof' (password: 1234) → Class Management to begin grading
-- ============================================================

SET SQL_SAFE_UPDATES = 1;
