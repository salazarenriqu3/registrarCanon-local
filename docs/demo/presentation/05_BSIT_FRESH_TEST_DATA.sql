-- ==============================================================================
-- BSIT FRESH PC TEST DATA SEED
-- ==============================================================================
-- Run this script to generate all necessary data to test a student moving
-- from Applicant -> 1st Year -> 4th Year on a completely FRESH database.
-- It seeds the Curriculum, Academic Terms, Fees, Class Sections, and an Applicant.
-- ==============================================================================

USE eacdb;

-- =============================================================================
-- 1. SET BSIT Official Curriculum (Effective S.Y. 2024-2025)
-- =============================================================================
INSERT IGNORE INTO departments (department_id, department_code, department_name) VALUES (1, 'SCS', 'School of Computer Studies');
SET @dept_id = COALESCE(
    (SELECT department_id FROM programs WHERE program_code = 'BSIT' LIMIT 1),
    (SELECT department_id FROM departments LIMIT 1),
    1
);

SET @curriculum_id = (
    SELECT ct.curriculum_id
    FROM curriculum_templates ct
    JOIN programs p ON ct.program_id = p.program_id
    WHERE p.program_code = 'BSIT' AND ct.is_active = 1
    ORDER BY (ct.approval_status = 'Approved') DESC, ct.curriculum_id DESC
    LIMIT 1
);

INSERT INTO curriculum_templates
    (program_id, curriculum_name, academic_year, version_number, approval_status, is_active)
SELECT
    p.program_id,
    'SET BSIT (Official 2024-2025)',
    '2024-2025',
    1,
    'Approved',
    1
FROM programs p
WHERE p.program_code = 'BSIT'
  AND @curriculum_id IS NULL
  AND NOT EXISTS (
      SELECT 1
      FROM curriculum_templates ct2
      WHERE ct2.program_id = p.program_id
  );

SET @curriculum_id = COALESCE(@curriculum_id, (
    SELECT ct.curriculum_id
    FROM curriculum_templates ct
    JOIN programs p ON ct.program_id = p.program_id
    WHERE p.program_code = 'BSIT'
    ORDER BY ct.is_active DESC, ct.curriculum_id DESC
    LIMIT 1
));

UPDATE curriculum_templates ct
JOIN programs p ON ct.program_id = p.program_id
SET ct.is_active = 0
WHERE p.program_code = 'BSIT'
  AND ct.curriculum_id <> @curriculum_id;

UPDATE curriculum_templates
SET curriculum_name = 'SET BSIT (Official 2024-2025)',
    academic_year = '2024-2025',
    approval_status = 'Approved',
    is_active = 1
WHERE curriculum_id = @curriculum_id;

SET @course_code_collate = (
    SELECT COLLATION_NAME
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'courses'
      AND COLUMN_NAME = 'course_code'
    LIMIT 1
);
SET @course_code_collate = IFNULL(@course_code_collate, 'utf8mb4_unicode_ci');

DROP TEMPORARY TABLE IF EXISTS bsit_curriculum_staging;
SET @create_staging = CONCAT(
    'CREATE TEMPORARY TABLE bsit_curriculum_staging (',
    'course_code VARCHAR(20) CHARACTER SET utf8mb4 COLLATE ', @course_code_collate, ' NOT NULL,',
    'course_title VARCHAR(200) CHARACTER SET utf8mb4 COLLATE ', @course_code_collate, ' NOT NULL,',
    'year_level INT NOT NULL,',
    'semester_number INT NOT NULL,',
    'lec_units INT NOT NULL DEFAULT 0,',
    'lab_units INT NOT NULL DEFAULT 0,',
    'PRIMARY KEY (course_code, year_level, semester_number)',
    ') DEFAULT CHARSET=utf8mb4 COLLATE ', @course_code_collate
);
PREPARE stmt FROM @create_staging;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- First Year — First Semester (10 courses)
INSERT INTO bsit_curriculum_staging VALUES
('AUS0 11',  'Understanding the Self',                              1, 1, 3, 0),
('ARPH 11',  'Readings in Philippine History',                      1, 1, 3, 0),
('SMMW 11',  'Mathematics in the Modern World',                     1, 1, 3, 0),
('AHU1 11',  'Art Appreciation',                                    1, 1, 3, 0),
('ASS1011',  'Social Sciences and Philosophy',                      1, 1, 3, 0),
('PE1 11',   'PE 1 (PATHFit 1): Movement Competency Training',      1, 1, 2, 0),
('ANS1 11',  'CWTS 1/LTS 1/ROTC 1',                                 1, 1, 3, 0),
('AECO 11',  'Emilian Culture',                                     1, 1, 1, 0),
('UCO1 11',  'Introduction to Information Technology',              1, 1, 2, 1),
('UPR1 11',  'Fundamentals of Problem Solving & Programming',       1, 1, 2, 1);

-- First Year — Second Semester (8 courses)
INSERT INTO bsit_curriculum_staging VALUES
('ACW0 12',  'The Contemporary World',                              1, 2, 3, 0),
('APC0 12',  'Purposive Communication',                             1, 2, 3, 0),
('AET0 12',  'Ethics',                                              1, 2, 3, 0),
('SMST012',  'Mathematics, Science & Technology',                   1, 2, 3, 0),
('PE2 12',   'PE 2 (PATHFit 2): Exercise-based Fitness Activities', 1, 2, 2, 0),
('ANS2 12',  'CWTS 2/LTS 2/ROTC 2',                                 1, 2, 3, 0),
('UHC1 11',  'Introduction to Human Computer Interaction',          1, 2, 2, 1),
('UPR2 12',  'Advanced Problem Solving & Programming',              1, 2, 2, 1);

-- Second Year — First Semester (7 courses)
INSERT INTO bsit_curriculum_staging VALUES
('AHU2 21',  'Arts and Humanities',                                 2, 1, 3, 0),
('ASS6 21',  'Life, Works & Writing of Rizal',                    2, 1, 3, 0),
('PE3 21',   'PE 3 (PATHFit 3): Basic Swimming',                    2, 1, 2, 0),
('BEC0 12',  'Accounting Principles',                               2, 1, 3, 0),
('UPR3 21',  'Object Oriented Programming',                         2, 1, 2, 1),
('UDM0 21',  'Discrete Mathematics',                                2, 1, 3, 0),
('UIM0 12',  'Introduction to Information Management',              2, 1, 2, 1);

-- Second Year — Second Semester (6 courses)
INSERT INTO bsit_curriculum_staging VALUES
('STS0 22',  'Science, Technology & Society',                       2, 2, 3, 0),
('PE4 22',   'PE 4 (PATHFit 4): Advance Swimming',                  2, 2, 2, 0),
('AEN4 22',  'Business Correspondence',                             2, 2, 3, 0),
('UNW122',   'Networking 1',                                        2, 2, 2, 1),
('UDS022',   'Data Structures and Algorithms',                      2, 2, 2, 1),
('UDB122',   'Database Management System 1',                        2, 2, 2, 1);

-- Third Year — First Semester (6 courses)
INSERT INTO bsit_curriculum_staging VALUES
('SMA3 21',  'Statistics',                                          3, 1, 3, 0),
('USI1 31',  'System Integration and Architecture 1',               3, 1, 2, 1),
('UNW2 31',  'Networking 2',                                        3, 1, 2, 1),
('UEL2 31',  'Tangible Technologies',                               3, 1, 2, 1),
('UEL131',   'Intangible Technologies',                               3, 1, 2, 1),
('UDB231',   'Advanced Database Systems',                           3, 1, 2, 1);

-- Third Year — Second Semester (5 courses)
INSERT INTO bsit_curriculum_staging VALUES
('UADET 32', 'Application Development and Emerging Technologies',     3, 2, 2, 1),
('UEDP0 32', 'Event Driven Programming',                            3, 2, 2, 1),
('UIAS1 32', 'Information Assurance and Security 1',                3, 2, 2, 1),
('UQM0 32',  'Quantitative Methods',                                3, 2, 3, 0),
('USPI 32',  'Social and Professional Issues',                      3, 2, 3, 0);

-- Fourth Year — First Semester (4 courses)
INSERT INTO bsit_curriculum_staging VALUES
('UCP1 41',  'Capstone Project 1',                                  4, 1, 3, 0),
('UIAS2 41', 'Information Assurance and Security 2',                4, 1, 2, 1),
('USAM0 41', 'Systems Administration and Maintenance',                4, 1, 2, 1),
('USI1 41',  'System Integration and Architecture 2',               4, 1, 2, 1);

-- Fourth Year — Second Semester (2 courses)
INSERT INTO bsit_curriculum_staging VALUES
('UCP2 42',  'Capstone Project 2',                                  4, 2, 3, 0),
('UOJT 42',  'On the Job Training',                                 4, 2, 9, 0);

-- Upsert courses (by course_code)
INSERT INTO courses (
    course_code, course_title, department_id, credit_units,
    lec_units, lab_units, lecture_hours_per_week, lab_hours_per_week,
    course_type, active_status, onlist
)
SELECT
    s.course_code,
    s.course_title,
    @dept_id,
    s.lec_units + s.lab_units,
    s.lec_units,
    s.lab_units,
    s.lec_units,
    s.lab_units,
    IF(s.lab_units > 0, 'Mixed', 'Lecture'),
    1,
    1
FROM bsit_curriculum_staging s
ON DUPLICATE KEY UPDATE
    course_title = VALUES(course_title),
    credit_units = VALUES(credit_units),
    lec_units = VALUES(lec_units),
    lab_units = VALUES(lab_units),
    lecture_hours_per_week = VALUES(lecture_hours_per_week),
    lab_hours_per_week = VALUES(lab_hours_per_week),
    course_type = VALUES(course_type),
    active_status = 1,
    onlist = 1;

-- Replace BSIT curriculum links only
DELETE FROM curriculum_courses WHERE curriculum_id = @curriculum_id;

INSERT INTO curriculum_courses (curriculum_id, course_id, year_level, semester_number, is_required)
SELECT @curriculum_id, c.course_id, s.year_level, s.semester_number, 1
FROM bsit_curriculum_staging s
JOIN courses c ON c.course_code = s.course_code;


-- =============================================================================
-- 2. Ensure 4 Years of Academic Terms Exist (8 Semesters)
-- =============================================================================
INSERT IGNORE INTO academic_terms (term_code, term_name, start_date, end_date, status, is_active, semester_number) VALUES
('1120242025', '1st Semester 2024-2025', '2024-08-01', '2024-12-15', 'ACTIVE', 1, 1),
('2120242025', '2nd Semester 2024-2025', '2025-01-15', '2025-05-30', 'INACTIVE', 0, 2),
('1120252026', '1st Semester 2025-2026', '2025-08-01', '2025-12-15', 'INACTIVE', 0, 1),
('2120252026', '2nd Semester 2025-2026', '2026-01-15', '2026-05-30', 'INACTIVE', 0, 2),
('1120262027', '1st Semester 2026-2027', '2026-08-01', '2026-12-15', 'INACTIVE', 0, 1),
('2120262027', '2nd Semester 2026-2027', '2027-01-15', '2027-05-30', 'INACTIVE', 0, 2),
('1120272028', '1st Semester 2027-2028', '2027-08-01', '2027-12-15', 'INACTIVE', 0, 1),
('2120272028', '2nd Semester 2027-2028', '2028-01-15', '2028-05-30', 'INACTIVE', 0, 2);

-- Set active term to 1120242025
UPDATE academic_terms SET is_active = 0, status = 'INACTIVE';
UPDATE academic_terms SET is_active = 1, status = 'ACTIVE' WHERE term_code = '1120242025';

INSERT INTO system_settings (setting_key, setting_value)
VALUES ('CURRENT_ACADEMIC_TERM', '1120242025')
ON DUPLICATE KEY UPDATE setting_value = '1120242025';


-- =============================================================================
-- 3. Set Up Program Fee Settings (Global Fallback - NULL term) for all 4 years
-- =============================================================================
SET @prog_id = (SELECT program_id FROM programs WHERE program_code = 'BSIT' LIMIT 1);

-- Clean old fee settings for BSIT to ensure clean test
DELETE FROM program_fee_settings WHERE program_id = @prog_id;

-- 1st Year Fees
INSERT INTO program_fee_settings (program_id, year_level, semester_number, term_id, fee_tuition_per_unit, fee_lec_per_unit, fee_lab_per_unit, fee_misc_registration, fee_misc_library, fee_misc_medical, is_active)
VALUES 
(@prog_id, 1, 1, NULL, 1500.00, 1500.00, 2000.00, 500.00, 300.00, 200.00, 1),
(@prog_id, 1, 2, NULL, 1500.00, 1500.00, 2000.00, 500.00, 300.00, 200.00, 1),
-- 2nd Year Fees
(@prog_id, 2, 1, NULL, 1600.00, 1600.00, 2100.00, 500.00, 300.00, 200.00, 1),
(@prog_id, 2, 2, NULL, 1600.00, 1600.00, 2100.00, 500.00, 300.00, 200.00, 1),
-- 3rd Year Fees 
(@prog_id, 3, 1, NULL, 1700.00, 1700.00, 2200.00, 500.00, 300.00, 200.00, 1),
(@prog_id, 3, 2, NULL, 1700.00, 1700.00, 2200.00, 500.00, 300.00, 200.00, 1),
-- 4th Year Fees 
(@prog_id, 4, 1, NULL, 1800.00, 1800.00, 2300.00, 500.00, 300.00, 200.00, 1),
(@prog_id, 4, 2, NULL, 1800.00, 1800.00, 2300.00, 500.00, 300.00, 200.00, 1);

UPDATE program_fee_settings SET fee_other_dev = 2000.00 WHERE program_id = @prog_id AND year_level = 4;


-- =============================================================================
-- 4. Generate Class Sections for the entire BSIT Curriculum across the 8 terms
-- =============================================================================
-- Delete existing generated sections for this test to avoid dupes
DELETE FROM class_sections WHERE section_code LIKE 'BSIT-%-A';

-- A temporary mapping table for Year/Sem -> Term Code
DROP TEMPORARY TABLE IF EXISTS lifecycle_term_map;
CREATE TEMPORARY TABLE lifecycle_term_map (
    year_level INT,
    semester_number INT,
    term_code VARCHAR(20)
);
INSERT INTO lifecycle_term_map VALUES 
(1, 1, '1120242025'), (1, 2, '2120242025'),
(2, 1, '1120252026'), (2, 2, '2120252026'),
(3, 1, '1120262027'), (3, 2, '2120262027'),
(4, 1, '1120272028'), (4, 2, '2120272028');

-- Insert the sections
INSERT INTO class_sections (term_id, course_id, section_code, max_capacity, section_status, semester_number)
SELECT 
    t.term_id,
    cc.course_id,
    CONCAT('BSIT-', cc.year_level, '-', cc.semester_number, '-A'),
    40,
    'Open',
    cc.semester_number
FROM curriculum_courses cc
JOIN lifecycle_term_map ltm ON cc.year_level = ltm.year_level AND cc.semester_number = ltm.semester_number
JOIN academic_terms t ON t.term_code = ltm.term_code
WHERE cc.curriculum_id = @curriculum_id;


-- =============================================================================
-- 5. Create a Fresh Applicant
-- =============================================================================
-- Clean up previous test runs for this applicant and recreate
DELETE FROM applicant_payments WHERE applicant_id = 'REF-BSIT-FRESH';
DELETE FROM payments WHERE reference_number = 'REF-BSIT-FRESH';
DELETE FROM applicants WHERE reference_number = 'REF-BSIT-FRESH';

INSERT INTO applicants (
    reference_number, first_name, last_name, email, 
    program1, applicant_status, term_year, created_at, updated_at
)
VALUES (
    'REF-BSIT-FRESH', 'Fresh', 'Applicant', 'fresh.applicant@example.com', 
    'BSIT', 'Pending', '1120242025', NOW(), NOW()
);

SELECT 'Test data successfully generated! Applicant REF-BSIT-FRESH is ready to be enrolled.' AS Result;
