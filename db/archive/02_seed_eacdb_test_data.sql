-- =============================================================================
-- EACDB — TEST DATA SEED SCRIPT (Mock Curriculum & Term Offerings)
-- =============================================================================
USE eacdb;
SET FOREIGN_KEY_CHECKS = 0;

-- 1. Mock Departments
INSERT IGNORE INTO departments (department_id, department_code, department_name, building_location, created_at, updated_at) VALUES 
(1, 'SCS', 'School of Computer Studies', 'Main Building 3rd Floor', NOW(), NOW()),
(2, 'SAS', 'School of Arts and Sciences', 'Main Building 2nd Floor', NOW(), NOW());

-- 2. Mock Academic Terms
INSERT IGNORE INTO academic_terms (term_id, term_code, term_name, start_date, end_date, status) VALUES 
(1, '1120242025', 'First Semester 2024-2025', '2024-08-01', '2024-12-15', 'ACTIVE'),
(2, '2120242025', 'Second Semester 2024-2025', '2025-01-15', '2025-05-30', 'INACTIVE');

-- 3. Mock Faculty
INSERT IGNORE INTO faculty (faculty_id, employee_number, first_name, last_name, email, department_id, employment_type, max_teaching_units, active_status) VALUES 
(1, 'EMP-1001', 'Alan', 'Turing', 'aturing@school.edu.ph', 1, 'FULL_TIME', 24, 1),
(2, 'EMP-1002', 'Ada', 'Lovelace', 'alovelace@school.edu.ph', 1, 'FULL_TIME', 24, 1),
(3, 'EMP-1003', 'Jose', 'Rizal', 'jrizal@school.edu.ph', 2, 'PART_TIME', 12, 1);

-- 4. Mock Rooms
INSERT IGNORE INTO rooms (room_id, room_code, building_name, capacity, room_type, active_status) VALUES 
(1, 'LAB-301', 'Main Building', 40, 'Computer Lab', 1),
(2, 'LEC-205', 'Main Building', 50, 'Lecture', 1);

-- 5. Canonical Programs (replaces jp_programs)
INSERT IGNORE INTO programs (program_id, program_code, program_name, school_name, department_id, active_status) VALUES
-- School of Computer Studies (dept 1)
(1,  'BSIT',   'Bachelor of Science in Information Technology',     'School of Computer Studies',  1, 1),
(2,  'BSCS',   'Bachelor of Science in Computer Science',           'School of Computer Studies',  1, 1),
-- School of Arts and Sciences (dept 2)
(3,  'BSBio',  'Bachelor of Science in Biology',                    'School of Arts and Sciences', 2, 1),
(4,  'BSMATH', 'Bachelor of Science in Mathematics',                'School of Arts and Sciences', 2, 1),
(5,  'ABCOMM', 'Bachelor of Arts in Communication',                 'School of Arts and Sciences', 2, 1),
-- School of Business (dept 3 — insert dept first if missing)
(6,  'BSBA',   'Bachelor of Science in Business Administration',    'School of Business',          1, 1),
(7,  'BSA',    'Bachelor of Science in Accountancy',                'School of Business',          1, 1),
-- School of Education (dept 2)
(8,  'BSED',   'Bachelor of Secondary Education',                   'School of Education',         2, 1),
(9,  'BEED',   'Bachelor of Elementary Education',                  'School of Education',         2, 1),
-- School of Criminal Justice (dept 1)
(10, 'BSCrim', 'Bachelor of Science in Criminology',                'School of Criminal Justice',  1, 1),
-- School of Health Sciences (dept 2)
(11, 'BSN',    'Bachelor of Science in Nursing',                    'School of Health Sciences',   2, 1),
(12, 'BSMT',   'Bachelor of Science in Medical Technology',         'School of Health Sciences',   2, 1),
-- Engineering (dept 1)
(13, 'BSECE',  'Bachelor of Science in Electronics Engineering',    'School of Engineering',       1, 1),
(14, 'BSCE',   'Bachelor of Science in Civil Engineering',          'School of Engineering',       1, 1);


-- 6. Mock Courses (Comprehensive Curriculum)
-- department_id 1 = SCS (Major subjects), 2 = SAS (Shared/GE subjects)
-- NOTE: semester, year_level, program_code removed from courses table (now in curriculum_courses)
INSERT IGNORE INTO courses (course_id, course_code, course_title, department_id, description, credit_units, lecture_hours_per_week, lab_hours_per_week, max_students, course_type, active_status) VALUES
-- Year 1 Sem 1
(101, 'CC101',   'Introduction to Computing',             1, 'Basic concepts of computing',              3, 2, 3, 40, 'MAJOR', 1),
(102, 'CC102',   'Computer Programming 1',                1, 'Fundamentals of Programming in C/Java',    3, 2, 3, 40, 'MAJOR', 1),
(103, 'GE101',   'Understanding the Self',                2, 'General Education Course',                 3, 3, 0, 50, 'MINOR', 1),
(104, 'GE102',   'Readings in Philippine History',        2, 'General Education Course',                 3, 3, 0, 50, 'MINOR', 1),
(105, 'PE101',   'Physical Education 1',                  2, 'Movement Enhancement',                     2, 2, 0, 50, 'MINOR', 1),
(106, 'NSTP101', 'National Service Training Program 1',   2, 'Civic Welfare Training Service',           3, 3, 0, 50, 'MINOR', 1),
-- Year 1 Sem 2
(107, 'CC103',   'Computer Programming 2',                1, 'Advanced Programming in C/Java',           3, 2, 3, 40, 'MAJOR', 1),
(108, 'IT104',   'Data Structures and Algorithms',        1, 'Structures for BSIT',                      3, 2, 3, 40, 'MAJOR', 1),
(109, 'CS104',   'Discrete Structures 1',                 1, 'Math logic for BSCS',                      3, 3, 0, 40, 'MAJOR', 1),
(110, 'GE103',   'The Contemporary World',                2, 'General Education Course',                 3, 3, 0, 50, 'MINOR', 1),
(111, 'GE104',   'Mathematics in the Modern World',       2, 'General Education Course',                 3, 3, 0, 50, 'MINOR', 1),
(112, 'PE102',   'Physical Education 2',                  2, 'Fitness Exercises',                        2, 2, 0, 50, 'MINOR', 1),
(113, 'NSTP102', 'National Service Training Program 2',   2, 'Civic Welfare Training Service 2',         3, 3, 0, 50, 'MINOR', 1),
-- Year 2 Sem 1
(201, 'IT201',   'Human Computer Interaction',            1, 'HCI for BSIT',                             3, 2, 3, 40, 'MAJOR', 1),
(202, 'CS201',   'Object Oriented Programming',           1, 'OOP for BSCS',                             3, 2, 3, 40, 'MAJOR', 1),
(203, 'GE201',   'Purposive Communication',               2, 'General Education Course',                 3, 3, 0, 50, 'MINOR', 1);

-- 7a. Curriculum Templates — one active curriculum per program
INSERT IGNORE INTO curriculum_templates (curriculum_id, program_id, curriculum_name, academic_year, version_number, approval_status, is_active) VALUES
(1, 1, 'BSIT Curriculum', '2024-2025', 1, 'Approved', 1),
(2, 2, 'BSCS Curriculum', '2024-2025', 1, 'Approved', 1);

-- 7b. Curriculum Courses — maps each course to its program/year/semester
--     BSIT curriculum_id = 1 | BSCS curriculum_id = 2
INSERT IGNORE INTO curriculum_courses (curriculum_id, course_id, year_level, semester_number, is_required) VALUES
-- BSIT Year 1 Sem 1
(1, 101, 1, 1, 1), (1, 102, 1, 1, 1), (1, 103, 1, 1, 1),
(1, 104, 1, 1, 1), (1, 105, 1, 1, 1), (1, 106, 1, 1, 1),
-- BSCS Year 1 Sem 1 (same shared subjects)
(2, 101, 1, 1, 1), (2, 102, 1, 1, 1), (2, 103, 1, 1, 1),
(2, 104, 1, 1, 1), (2, 105, 1, 1, 1), (2, 106, 1, 1, 1),

-- BSIT Year 1 Sem 2
(1, 107, 1, 2, 1), (1, 108, 1, 2, 1), (1, 110, 1, 2, 1),
(1, 111, 1, 2, 1), (1, 112, 1, 2, 1), (1, 113, 1, 2, 1),
-- BSCS Year 1 Sem 2 (uses CS104 instead of IT104)
(2, 107, 1, 2, 1), (2, 109, 1, 2, 1), (2, 110, 1, 2, 1),
(2, 111, 1, 2, 1), (2, 112, 1, 2, 1), (2, 113, 1, 2, 1),

-- BSIT Year 2 Sem 1
(1, 201, 2, 1, 1), (1, 203, 2, 1, 1),
-- BSCS Year 2 Sem 1
(2, 202, 2, 1, 1), (2, 203, 2, 1, 1);

-- 8. Mock Term Offerings: Class Sections (term_id = 1, First Semester)
-- We need sections open so that block enrollment has slots to assign to students.
INSERT IGNORE INTO class_sections (section_id, course_id, term_id, section_code, faculty_id, max_capacity, section_status) VALUES 
-- Year 1 Sem 1 Sections
(1001, 101, 1, 'CC101-A', 1, 40, 'Active'),
(1002, 102, 1, 'CC102-A', 2, 40, 'Active'),
(1003, 103, 1, 'GE101-A', 3, 50, 'Active'),
(1004, 104, 1, 'GE102-A', 3, 50, 'Active'),
(1005, 105, 1, 'PE101-A', NULL, 50, 'Active'),
(1006, 106, 1, 'NSTP101-A', NULL, 50, 'Active'),

-- Year 2 Sem 1 Sections
(2001, 201, 1, 'IT201-A', 1, 40, 'Active'),
(2002, 202, 1, 'CS201-A', 2, 40, 'Active'),
(2003, 203, 1, 'GE201-A', 3, 50, 'Active');

-- 9. Mock Term Offerings: Class Schedules
-- day_of_week: 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat, 7=Sun
INSERT IGNORE INTO class_schedules (schedule_id, section_id, room_id, faculty_id, day_of_week, start_time, end_time, schedule_type) VALUES 
-- Year 1 Sem 1
(1, 1001, 1, 1, 1, '09:00:00', '12:00:00', 'Lecture'), -- CC101 Mon 9-12
(2, 1002, 1, 2, 2, '09:00:00', '12:00:00', 'Lecture'), -- CC102 Tue 9-12
(3, 1003, 2, 3, 3, '10:00:00', '13:00:00', 'Lecture'), -- GE101 Wed 10-1
(4, 1004, 2, 3, 4, '13:00:00', '16:00:00', 'Lecture'), -- GE102 Thu 1-4
(5, 1005, NULL, NULL, 5, '08:00:00', '10:00:00', 'Lecture'), -- PE101 Fri 8-10
(6, 1006, NULL, NULL, 6, '08:00:00', '11:00:00', 'Lecture'), -- NSTP101 Sat 8-11

-- Year 2 Sem 1
(7, 2001, 1, 1, 1, '13:00:00', '16:00:00', 'Lecture'), -- IT201 Mon 1-4
(8, 2002, 1, 2, 2, '13:00:00', '16:00:00', 'Lecture'), -- CS201 Tue 1-4
(9, 2003, 2, 3, 3, '14:00:00', '17:00:00', 'Lecture'); -- GE201 Wed 2-5

SET FOREIGN_KEY_CHECKS = 1;
