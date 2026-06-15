-- =============================================================================
-- TEST DATA SCRIPT: BSIT Curriculum, Sections & Mock Applicant (IT-TEST-001)
-- Run this script in your MySQL client (e.g., phpMyAdmin, MySQL Workbench)
-- =============================================================================

USE eacdb;
SET FOREIGN_KEY_CHECKS = 0;

-- 1. Programs & Curriculum Templates
INSERT IGNORE INTO programs (program_id, program_code, program_name, active_status) 
VALUES (101, 'BSIT', 'Bachelor of Science in Information Technology', 1);

INSERT IGNORE INTO curriculum_templates (curriculum_id, program_id, curriculum_name, is_active)
VALUES (101, 101, 'BSIT Standard Curriculum', 1);

-- 2. Mock Applicant for Testing
INSERT IGNORE INTO applicants (
    reference_number, first_name, last_name, email, program1, 
    applicant_status, mobile, term_year
) VALUES (
    'IT-TEST-001', 'Juan', 'Dela Cruz', 'juan.delacruz@example.com', 'BSIT', 
    'QUALIFIED FOR ENROLLMENT', '09123456789', 'SL_1120252026'
);



-- 3. Courses (Enrollment3 canonical source)
-- YEAR 1
INSERT IGNORE INTO courses (course_id, course_code, course_title, department_id, credit_units) VALUES (1001, 'IT111', 'Introduction to Computing', 1, 3);
INSERT IGNORE INTO courses (course_id, course_code, course_title, department_id, credit_units) VALUES (1002, 'IT112', 'Computer Programming 1', 1, 3);
INSERT IGNORE INTO courses (course_id, course_code, course_title, department_id, credit_units) VALUES (1003, 'IT121', 'Computer Programming 2', 1, 3);
INSERT IGNORE INTO courses (course_id, course_code, course_title, department_id, credit_units) VALUES (1004, 'IT122', 'Data Structures and Algorithms', 1, 3);

-- YEAR 2
INSERT IGNORE INTO courses (course_id, course_code, course_title, department_id, credit_units) VALUES (1005, 'IT211', 'Database Management Systems 1', 1, 3);
INSERT IGNORE INTO courses (course_id, course_code, course_title, department_id, credit_units) VALUES (1006, 'IT212', 'Networking 1', 1, 3);
INSERT IGNORE INTO courses (course_id, course_code, course_title, department_id, credit_units) VALUES (1007, 'IT221', 'Information Management', 1, 3);
INSERT IGNORE INTO courses (course_id, course_code, course_title, department_id, credit_units) VALUES (1008, 'IT222', 'Systems Integration and Architecture 1', 1, 3);

-- YEAR 3
INSERT IGNORE INTO courses (course_id, course_code, course_title, department_id, credit_units) VALUES (1009, 'IT311', 'Web Systems and Technologies', 1, 3);
INSERT IGNORE INTO courses (course_id, course_code, course_title, department_id, credit_units) VALUES (1010, 'IT312', 'Information Assurance and Security', 1, 3);
INSERT IGNORE INTO courses (course_id, course_code, course_title, department_id, credit_units) VALUES (1011, 'IT321', 'Capstone Project and Research 1', 1, 3);
INSERT IGNORE INTO courses (course_id, course_code, course_title, department_id, credit_units) VALUES (1012, 'IT322', 'Systems Administration and Maintenance', 1, 3);

-- YEAR 4
INSERT IGNORE INTO courses (course_id, course_code, course_title, department_id, credit_units) VALUES (1013, 'IT411', 'Capstone Project and Research 2', 1, 3);
INSERT IGNORE INTO courses (course_id, course_code, course_title, department_id, credit_units) VALUES (1014, 'IT412', 'Practicum / Internship 1', 1, 6);
INSERT IGNORE INTO courses (course_id, course_code, course_title, department_id, credit_units) VALUES (1015, 'IT421', 'Practicum / Internship 2', 1, 6);
INSERT IGNORE INTO courses (course_id, course_code, course_title, department_id, credit_units) VALUES (1016, 'IT422', 'IT Seminars and Field Trips', 1, 3);

-- 4. Map Courses to BSIT Curriculum (curriculum_courses)
-- YEAR 1
INSERT IGNORE INTO curriculum_courses (curriculum_id, course_id, year_level, semester_number) VALUES (101, 1001, 1, 1);
INSERT IGNORE INTO curriculum_courses (curriculum_id, course_id, year_level, semester_number) VALUES (101, 1002, 1, 1);
INSERT IGNORE INTO curriculum_courses (curriculum_id, course_id, year_level, semester_number) VALUES (101, 1003, 1, 2);
INSERT IGNORE INTO curriculum_courses (curriculum_id, course_id, year_level, semester_number) VALUES (101, 1004, 1, 2);
-- YEAR 2
INSERT IGNORE INTO curriculum_courses (curriculum_id, course_id, year_level, semester_number) VALUES (101, 1005, 2, 1);
INSERT IGNORE INTO curriculum_courses (curriculum_id, course_id, year_level, semester_number) VALUES (101, 1006, 2, 1);
INSERT IGNORE INTO curriculum_courses (curriculum_id, course_id, year_level, semester_number) VALUES (101, 1007, 2, 2);
INSERT IGNORE INTO curriculum_courses (curriculum_id, course_id, year_level, semester_number) VALUES (101, 1008, 2, 2);
-- YEAR 3
INSERT IGNORE INTO curriculum_courses (curriculum_id, course_id, year_level, semester_number) VALUES (101, 1009, 3, 1);
INSERT IGNORE INTO curriculum_courses (curriculum_id, course_id, year_level, semester_number) VALUES (101, 1010, 3, 1);
INSERT IGNORE INTO curriculum_courses (curriculum_id, course_id, year_level, semester_number) VALUES (101, 1011, 3, 2);
INSERT IGNORE INTO curriculum_courses (curriculum_id, course_id, year_level, semester_number) VALUES (101, 1012, 3, 2);
-- YEAR 4
INSERT IGNORE INTO curriculum_courses (curriculum_id, course_id, year_level, semester_number) VALUES (101, 1013, 4, 1);
INSERT IGNORE INTO curriculum_courses (curriculum_id, course_id, year_level, semester_number) VALUES (101, 1014, 4, 1);
INSERT IGNORE INTO curriculum_courses (curriculum_id, course_id, year_level, semester_number) VALUES (101, 1015, 4, 2);
INSERT IGNORE INTO curriculum_courses (curriculum_id, course_id, year_level, semester_number) VALUES (101, 1016, 4, 2);

-- 5. Open Sections for these Courses (Assuming Term ID 1 is active)
-- Ensures the sections show up in the Registrar Enrollment Hub
INSERT IGNORE INTO class_sections (course_id, term_id, section_code, max_capacity, section_status) VALUES (1001, 1, 'BSIT-1A', 40, 'Open');
INSERT IGNORE INTO class_sections (course_id, term_id, section_code, max_capacity, section_status) VALUES (1002, 1, 'BSIT-1A', 40, 'Open');
INSERT IGNORE INTO class_sections (course_id, term_id, section_code, max_capacity, section_status) VALUES (1003, 1, 'BSIT-1A', 40, 'Open');
INSERT IGNORE INTO class_sections (course_id, term_id, section_code, max_capacity, section_status) VALUES (1004, 1, 'BSIT-1A', 40, 'Open');

INSERT IGNORE INTO class_sections (course_id, term_id, section_code, max_capacity, section_status) VALUES (1005, 1, 'BSIT-2A', 40, 'Open');
INSERT IGNORE INTO class_sections (course_id, term_id, section_code, max_capacity, section_status) VALUES (1006, 1, 'BSIT-2A', 40, 'Open');
INSERT IGNORE INTO class_sections (course_id, term_id, section_code, max_capacity, section_status) VALUES (1007, 1, 'BSIT-2A', 40, 'Open');
INSERT IGNORE INTO class_sections (course_id, term_id, section_code, max_capacity, section_status) VALUES (1008, 1, 'BSIT-2A', 40, 'Open');

INSERT IGNORE INTO class_sections (course_id, term_id, section_code, max_capacity, section_status) VALUES (1009, 1, 'BSIT-3A', 40, 'Open');
INSERT IGNORE INTO class_sections (course_id, term_id, section_code, max_capacity, section_status) VALUES (1010, 1, 'BSIT-3A', 40, 'Open');
INSERT IGNORE INTO class_sections (course_id, term_id, section_code, max_capacity, section_status) VALUES (1011, 1, 'BSIT-3A', 40, 'Open');
INSERT IGNORE INTO class_sections (course_id, term_id, section_code, max_capacity, section_status) VALUES (1012, 1, 'BSIT-3A', 40, 'Open');

INSERT IGNORE INTO class_sections (course_id, term_id, section_code, max_capacity, section_status) VALUES (1013, 1, 'BSIT-4A', 40, 'Open');
INSERT IGNORE INTO class_sections (course_id, term_id, section_code, max_capacity, section_status) VALUES (1014, 1, 'BSIT-4A', 40, 'Open');
INSERT IGNORE INTO class_sections (course_id, term_id, section_code, max_capacity, section_status) VALUES (1015, 1, 'BSIT-4A', 40, 'Open');
INSERT IGNORE INTO class_sections (course_id, term_id, section_code, max_capacity, section_status) VALUES (1016, 1, 'BSIT-4A', 40, 'Open');

SET FOREIGN_KEY_CHECKS = 1;
