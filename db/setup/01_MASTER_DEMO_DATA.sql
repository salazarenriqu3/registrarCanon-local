-- =============================================================================
-- SET BSIT Official Curriculum (Effective S.Y. 2024-2025)
-- Source: src/main/resources/curriculums/School of Engineering and Technology/SET BSIT.docx
--
-- Run after 00_upsert_academic_terms_calendar.sql (recommended polish order).
-- Replaces BSCS-clone rows in curriculum_courses for the active BSIT template.
-- Does NOT delete legacy courses (CC101, GE101, etc.) — only removes them from BSIT curriculum links.
--
-- Term alignment (enrollment TermParserUtil / registrar academic_terms):
--   curriculum cc.year_level + cc.semester_number = student year/sem slot (Y1S2 → 1, 2)
--   class_sections.term_id = calendar term where semester_number matches (e.g. 2120242025 for 2nd sem)
--   student term_year SL_2120242025 (Y1, 2nd sem, A.Y. 2024-2025) → DB code 2120242025
-- =============================================================================
USE eacdb;

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

-- Staging must match courses.course_code collation (db/fix = general_ci; some dumps = unicode_ci)
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

-- Legacy alias used in some grade seeds (optional compatibility)
INSERT INTO courses (
    course_code, course_title, department_id, credit_units,
    lec_units, lab_units, lecture_hours_per_week, lab_hours_per_week,
    course_type, active_status, onlist
)
SELECT 'AEC0 11', 'Emilian Culture', @dept_id, 1, 1, 0, 1, 0, 'Lecture', 1, 1
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM courses WHERE course_code = 'AEC0 11')
ON DUPLICATE KEY UPDATE course_title = 'Emilian Culture', active_status = 1, onlist = 1;

-- Replace BSIT curriculum links only
DELETE FROM curriculum_courses WHERE curriculum_id = @curriculum_id;

INSERT INTO curriculum_courses (curriculum_id, course_id, year_level, semester_number, is_required)
SELECT @curriculum_id, c.course_id, s.year_level, s.semester_number, 1
FROM bsit_curriculum_staging s
JOIN courses c ON c.course_code = s.course_code;

-- Summary
SELECT @curriculum_id AS curriculum_id,
       (SELECT curriculum_name FROM curriculum_templates WHERE curriculum_id = @curriculum_id) AS curriculum_name,
       COUNT(*) AS official_course_rows
FROM curriculum_courses
WHERE curriculum_id = @curriculum_id;

SELECT cc.year_level, cc.semester_number, COUNT(*) AS subjects
FROM curriculum_courses cc
WHERE cc.curriculum_id = @curriculum_id
GROUP BY cc.year_level, cc.semester_number
ORDER BY cc.year_level, cc.semester_number;

SELECT c.course_code, c.course_title, cc.year_level, cc.semester_number,
       c.lec_units, c.lab_units, c.credit_units
FROM curriculum_courses cc
JOIN courses c ON cc.course_id = c.course_id
WHERE cc.curriculum_id = @curriculum_id
ORDER BY cc.year_level, cc.semester_number, c.course_code;
-- =============================================================================
-- Marian School of Nursing � BSN Official Curriculum (Effective S.Y. 2024-2025)
-- Source reference: enrollment3/src/main/resources/curriculums/Marian School of Nursing/bsNursing.docx
--
-- Purpose:
--   Seeds the complete BSN curriculum for lifecycle testing.
--   Safe to re-run. Does not delete students, enlistments, ledger, payments, or grades.
--
-- Run before:
--   01_seed_bsn_class_sections_demo.sql
-- =============================================================================
SET NAMES utf8mb4 COLLATE utf8mb4_general_ci;
USE eacdb;

SET @program_id = (
    SELECT program_id
    FROM programs
    WHERE program_code = 'BSN'
    LIMIT 1
);

SET @dept_id = COALESCE(
    (SELECT department_id FROM programs WHERE program_code = 'BSN' LIMIT 1),
    (SELECT department_id FROM departments WHERE department_name LIKE '%Nurs%' LIMIT 1),
    (SELECT department_id FROM departments LIMIT 1),
    1
);

INSERT INTO programs (program_code, program_name, school_name, department_id, active_status, level)
SELECT
    'BSN',
    'Bachelor of Science in Nursing',
    'Marian School of Nursing',
    @dept_id,
    1,
    'COLLEGE'
WHERE @program_id IS NULL;

SET @program_id = (
    SELECT program_id
    FROM programs
    WHERE program_code = 'BSN'
    LIMIT 1
);

SET @curriculum_id = (
    SELECT ct.curriculum_id
    FROM curriculum_templates ct
    WHERE ct.program_id = @program_id
      AND ct.curriculum_name = 'Marian BSN (Official 2024-2025)'
    ORDER BY ct.curriculum_id DESC
    LIMIT 1
);

INSERT INTO curriculum_templates
    (program_id, curriculum_name, academic_year, version_number, approval_status, is_active)
SELECT
    @program_id,
    'Marian BSN (Official 2024-2025)',
    '2024-2025',
    1,
    'Approved',
    1
WHERE @curriculum_id IS NULL;

SET @curriculum_id = COALESCE(@curriculum_id, (
    SELECT ct.curriculum_id
    FROM curriculum_templates ct
    WHERE ct.program_id = @program_id
      AND ct.curriculum_name = 'Marian BSN (Official 2024-2025)'
    ORDER BY ct.curriculum_id DESC
    LIMIT 1
));

UPDATE curriculum_templates
SET is_active = 0
WHERE program_id = @program_id
  AND curriculum_id <> @curriculum_id;

UPDATE curriculum_templates
SET curriculum_name = 'Marian BSN (Official 2024-2025)',
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

DROP TEMPORARY TABLE IF EXISTS bsn_curriculum_staging;
SET @create_staging = CONCAT(
    'CREATE TEMPORARY TABLE bsn_curriculum_staging (',
    'course_code VARCHAR(20) CHARACTER SET utf8mb4 COLLATE ', @course_code_collate, ' NOT NULL,',
    'course_title VARCHAR(255) CHARACTER SET utf8mb4 COLLATE ', @course_code_collate, ' NOT NULL,',
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

-- Year 1 � First Semester (9 subjects / 28 units)
INSERT INTO bsn_curriculum_staging VALUES
('AECO 11', 'Emilian Culture', 1, 1, 1, 0),
('ANS1 11', 'CWTS 1/LTS 1/ROTC 1', 1, 1, 3, 0),
('ARPH 11', 'Readings in Philippine History', 1, 1, 3, 0),
('AUS0 11', 'Understanding the Self', 1, 1, 3, 0),
('NTFN011', 'Theoretical Foundations in Nursing', 1, 1, 3, 0),
('OAP0 11', 'Human Anatomy and Physiology with Pathophysiology', 1, 1, 3, 2),
('PE1 11', 'PE 1 (PATHFit 1): Movement Competency Training', 1, 1, 2, 0),
('SCH4 21', 'Biochemistry', 1, 1, 3, 2),
('SMMW 11', 'Mathematics in the Modern World', 1, 1, 3, 0);

-- Year 1 � Second Semester (8 subjects / 27 units)
INSERT INTO bsn_curriculum_staging VALUES
('AET0 12', 'Ethics', 1, 2, 3, 0),
('ANS2 12', 'CWTS 2/LTS 2/ROTC 2', 1, 2, 3, 0),
('APC0 12', 'Purposive Communication', 1, 2, 3, 0),
('MMP0421', 'Microbiology and Parasitology', 1, 2, 3, 1),
('NCM1A12', 'Fundamentals of Nursing Practice', 1, 2, 3, 2),
('NHA0512', 'Health Assessment', 1, 2, 3, 2),
('NHE0 23', 'Health Education', 1, 2, 3, 0),
('PE2 12', 'PE 2 (PATHFit 2): Exercise-based Fitness Activities', 1, 2, 2, 0);

-- Year 2 � First Semester (7 subjects / 29 units)
INSERT INTO bsn_curriculum_staging VALUES
('AHU2 21', 'Arts and Humanities', 2, 1, 3, 0),
('ASS6 21', 'Life, Works and Writings of Rizal', 2, 1, 3, 0),
('NCHN1', 'Community Health Nursing 1', 2, 1, 2, 2),
('NCM721', 'Care of Mother, Child, Adolescent (Well Clients)', 2, 1, 4, 5),
('NND021', 'Nutrition and Diet Therapy', 2, 1, 2, 1),
('NPH0 22', 'Pharmacology', 2, 1, 3, 0),
('PE3 21', 'PE 3 (PATHFit 3): Basic Swimming', 2, 1, 2, 0);

-- Year 2 � Second Semester (6 subjects / 26 units)
INSERT INTO bsn_curriculum_staging VALUES
('NCM922', 'Care of Mother, Child at Risk or with Problems (Acute and Chronic)', 2, 2, 6, 6),
('NET0 22', 'Health Care Ethics (Bioethics)', 2, 2, 3, 0),
('PE4 22', 'PE 4 (PATHFit 4): Advance Swimming', 2, 2, 2, 0),
('SMA3021', 'Biostatistics', 2, 2, 3, 0),
('STS0 22', 'Science, Technology and Society', 2, 2, 3, 0),
('UCO211', 'Nursing Informatics', 2, 2, 2, 1);

-- Year 3 � First Semester (4 subjects / 25 units)
INSERT INTO bsn_curriculum_staging VALUES
('AHU1 11', 'Art Appreciation', 3, 1, 3, 0),
('ASS1011', 'Social Science and Philosophy', 3, 1, 3, 0),
('NCM831', 'Care of Clients with Problems in Oxygenation, Fluid and Electrolytes, Infectious, Inflammatory and Immunologic Response, Cellular Aberrations, Acute and Chronic', 3, 1, 8, 6),
('NRES131', 'Nursing Research 1', 3, 1, 2, 3);

-- Year 3 � Second Semester (6 subjects / 26 units)
INSERT INTO bsn_curriculum_staging VALUES
('ACW0 12', 'The Contemporary World', 3, 2, 3, 0),
('NCHN2', 'Community Health Nursing 2', 3, 2, 2, 1),
('NCM1432', 'Care of Older Adult', 3, 2, 2, 1),
('NCM1632', 'Care of Clients with Problems in Nutrition, Gastrointestinal, Metabolism and Endocrine, Perception and Coordination (Acute and Chronic)', 3, 2, 5, 4),
('NRES232', 'Nursing Research 2', 3, 2, 0, 2),
('SMST012', 'Mathematics Science and Technology', 3, 2, 3, 0);

-- Year 4 � First Semester (3 subjects / 21 units)
INSERT INTO bsn_curriculum_staging VALUES
('NCM117', 'Care of Clients with Maladaptive Patterns of Behavior, Acute and Chronic', 4, 1, 4, 4),
('NCM118', 'Nursing Care of Clients with Life Threatening Conditions/Acutely Ill/Multi-organ Problems, High Acuity and Emergency Situation, Acute and Chronic', 4, 1, 4, 5),
('NCM7A41', 'Nursing Leadership and Management A', 4, 1, 4, 0);

-- Year 4 � Second Semester (4 subjects / 20 units)
INSERT INTO bsn_curriculum_staging VALUES
('NCA 42', 'Nursing Competency Appraisal', 4, 2, 6, 0),
('NCM119B', 'Nursing Leadership and Management B', 4, 2, 0, 3),
('NCM120', 'Disaster Nursing', 4, 2, 2, 1),
('NCM121', 'Intensive Nursing Practicum (Hospital and Community Settings)', 4, 2, 0, 8);

INSERT INTO courses (
    course_code, course_title, department_id, credit_units,
    lec_units, lab_units, lecture_hours_per_week, lab_hours_per_week,
    course_type, active_status
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
    1
FROM bsn_curriculum_staging s
ON DUPLICATE KEY UPDATE
    course_title = VALUES(course_title),
    credit_units = VALUES(credit_units),
    lec_units = VALUES(lec_units),
    lab_units = VALUES(lab_units),
    lecture_hours_per_week = VALUES(lecture_hours_per_week),
    lab_hours_per_week = VALUES(lab_hours_per_week),
    course_type = VALUES(course_type),
    active_status = 1;

DELETE FROM curriculum_courses
WHERE curriculum_id = @curriculum_id;

INSERT INTO curriculum_courses (curriculum_id, course_id, year_level, semester_number, is_required)
SELECT @curriculum_id, c.course_id, s.year_level, s.semester_number, 1
FROM bsn_curriculum_staging s
JOIN courses c ON c.course_code = s.course_code;

SELECT @curriculum_id AS curriculum_id,
       'Marian BSN (Official 2024-2025)' AS curriculum_name,
       COUNT(*) AS official_course_rows
FROM curriculum_courses
WHERE curriculum_id = @curriculum_id;

SELECT cc.year_level, cc.semester_number, COUNT(*) AS subjects, SUM(c.credit_units) AS units
FROM curriculum_courses cc
JOIN courses c ON c.course_id = cc.course_id
WHERE cc.curriculum_id = @curriculum_id
GROUP BY cc.year_level, cc.semester_number
ORDER BY cc.year_level, cc.semester_number;

SELECT c.course_code, c.course_title, cc.year_level, cc.semester_number,
       c.lec_units, c.lab_units, c.credit_units
FROM curriculum_courses cc
JOIN courses c ON c.course_id = cc.course_id
WHERE cc.curriculum_id = @curriculum_id
ORDER BY cc.year_level, cc.semester_number, c.course_code;
-- =============================================================================
-- BSIT class sections for block enlistment (all calendar terms)
-- Run AFTER:
--   00_upsert_academic_terms_calendar.sql
--   00_seed_bsit_curriculum_set_official.sql
--
-- Creates BSIT-{Y}-{S}-A on every calendar term where curriculum semester matches.
-- Creates BSIT-1-{S}-B on 1st/2nd sem terms for Year 1 only.
--
-- Enrollment resolves term_id via student SL_* → DB term_code (TermParserUtil).
-- Example: Elon Y1 S2 + SL_2120242025 → term 2120242025 → sections for cc.semester_number = 2.
-- =============================================================================
SET NAMES utf8mb4 COLLATE utf8mb4_general_ci;
USE eacdb;

INSERT INTO class_sections (course_id, term_id, section_code, max_capacity, section_status, semester_number)
SELECT DISTINCT
    c.course_id,
    at.term_id,
    CONCAT('BSIT-', cc.year_level, '-', cc.semester_number, '-A'),
    40,
    'Open',
    cc.semester_number
FROM curriculum_courses cc
JOIN curriculum_templates ct ON cc.curriculum_id = ct.curriculum_id
JOIN programs p ON ct.program_id = p.program_id
JOIN courses c ON cc.course_id = c.course_id
JOIN academic_terms at
    ON at.term_code REGEXP '^[12]1[0-9]{8}$'
   AND at.semester_number = cc.semester_number
WHERE p.program_code = 'BSIT'
  AND ct.is_active = 1
  AND COALESCE(c.onlist, 1) = 1
  AND NOT EXISTS (
      SELECT 1
      FROM class_sections cs
      WHERE cs.course_id = c.course_id
        AND cs.term_id = at.term_id
        AND cs.section_code = CONCAT('BSIT-', cc.year_level, '-', cc.semester_number, '-A')
  );

INSERT INTO class_sections (course_id, term_id, section_code, max_capacity, section_status, semester_number)
SELECT DISTINCT
    c.course_id,
    at.term_id,
    CONCAT('BSIT-', cc.year_level, '-', cc.semester_number, '-B'),
    40,
    'Open',
    cc.semester_number
FROM curriculum_courses cc
JOIN curriculum_templates ct ON cc.curriculum_id = ct.curriculum_id
JOIN programs p ON ct.program_id = p.program_id
JOIN courses c ON cc.course_id = c.course_id
JOIN academic_terms at
    ON at.term_code REGEXP '^[12]1[0-9]{8}$'
   AND at.semester_number = cc.semester_number
WHERE p.program_code = 'BSIT'
  AND ct.is_active = 1
  AND cc.year_level = 1
  AND cc.semester_number IN (1, 2)
  AND COALESCE(c.onlist, 1) = 1
  AND NOT EXISTS (
      SELECT 1
      FROM class_sections cs
      WHERE cs.course_id = c.course_id
        AND cs.term_id = at.term_id
        AND cs.section_code = CONCAT('BSIT-', cc.year_level, '-', cc.semester_number, '-B')
  );

-- Summary: sections per calendar term (BSIT only)
SELECT at.term_code, at.term_name, COUNT(DISTINCT cs.section_id) AS bsit_sections
FROM academic_terms at
LEFT JOIN class_sections cs ON cs.term_id = at.term_id AND cs.section_code LIKE 'BSIT-%'
WHERE at.term_code REGEXP '^[12]1[0-9]{8}$'
GROUP BY at.term_id, at.term_code, at.term_name
ORDER BY at.term_code;

-- Open-term hint (does not change ACTIVE flag)
SET @open = (SELECT setting_value FROM system_settings WHERE setting_key = 'CURRENT_ACADEMIC_TERM' LIMIT 1);
SET @open_db = IF(
    @open LIKE 'SL\_%' AND LENGTH(@open) >= 13,
    CONCAT(SUBSTRING(@open, 4, 1), '1', SUBSTRING(@open, 6, 4), SUBSTRING(@open, 10, 4)),
    @open
);
SELECT @open AS current_academic_term_setting,
       @open_db AS resolved_db_term_code,
       (SELECT term_name FROM academic_terms WHERE term_code = @open_db LIMIT 1) AS resolved_term_name;
-- =============================================================================
-- BSN class sections and schedules for full lifecycle testing
--
-- Run AFTER:
--   00_upsert_academic_terms_calendar.sql
--   00_seed_bsn_curriculum_marian_official.sql
--
-- Creates:
--   BSN-{Y}-{S}-A on every calendar term where semester matches.
--   BSN-1-{S}-B for Year 1 second-block testing.
--   One simple OPEN schedule row per course section.
--
-- Safe to re-run. Does not delete enlistments, grades, payments, or ledger rows.
-- =============================================================================
SET NAMES utf8mb4 COLLATE utf8mb4_general_ci;
USE eacdb;

-- Open primary A blocks across all lifecycle terms.
INSERT INTO class_sections (course_id, term_id, section_code, max_capacity, section_status, semester_number)
SELECT DISTINCT
    c.course_id,
    at.term_id,
    CONCAT('BSN-', cc.year_level, '-', cc.semester_number, '-A'),
    40,
    'Open',
    cc.semester_number
FROM curriculum_courses cc
JOIN curriculum_templates ct ON cc.curriculum_id = ct.curriculum_id
JOIN programs p ON ct.program_id = p.program_id
JOIN courses c ON cc.course_id = c.course_id
JOIN academic_terms at
    ON at.term_code REGEXP '^[12]1[0-9]{8}$'
   AND at.semester_number = cc.semester_number
WHERE p.program_code = 'BSN'
  AND ct.is_active = 1
  AND COALESCE(c.onlist, 1) = 1
  AND NOT EXISTS (
      SELECT 1
      FROM class_sections cs
      WHERE cs.course_id = c.course_id
        AND cs.term_id = at.term_id
        AND cs.section_code = CONCAT('BSN-', cc.year_level, '-', cc.semester_number, '-A')
  );

-- Optional second block for first-year intake testing.
INSERT INTO class_sections (course_id, term_id, section_code, max_capacity, section_status, semester_number)
SELECT DISTINCT
    c.course_id,
    at.term_id,
    CONCAT('BSN-', cc.year_level, '-', cc.semester_number, '-B'),
    40,
    'Open',
    cc.semester_number
FROM curriculum_courses cc
JOIN curriculum_templates ct ON cc.curriculum_id = ct.curriculum_id
JOIN programs p ON ct.program_id = p.program_id
JOIN courses c ON cc.course_id = c.course_id
JOIN academic_terms at
    ON at.term_code REGEXP '^[12]1[0-9]{8}$'
   AND at.semester_number = cc.semester_number
WHERE p.program_code = 'BSN'
  AND ct.is_active = 1
  AND cc.year_level = 1
  AND cc.semester_number IN (1, 2)
  AND COALESCE(c.onlist, 1) = 1
  AND NOT EXISTS (
      SELECT 1
      FROM class_sections cs
      WHERE cs.course_id = c.course_id
        AND cs.term_id = at.term_id
        AND cs.section_code = CONCAT('BSN-', cc.year_level, '-', cc.semester_number, '-B')
  );

-- Make all generated BSN sections explicitly open.
UPDATE class_sections cs
JOIN courses c ON c.course_id = cs.course_id
JOIN curriculum_courses cc ON cc.course_id = c.course_id
JOIN curriculum_templates ct ON ct.curriculum_id = cc.curriculum_id
JOIN programs p ON p.program_id = ct.program_id
SET cs.section_status = 'Open',
    cs.max_capacity = COALESCE(cs.max_capacity, 40),
    cs.semester_number = cc.semester_number
WHERE p.program_code = 'BSN'
  AND ct.is_active = 1
  AND cs.section_code LIKE 'BSN-%';

-- Insert one deterministic schedule row per BSN section. No duplicate on rerun.
INSERT INTO class_schedules (section_id, room_id, faculty_id, day_of_week, start_time, end_time, schedule_type, status)
SELECT
    x.section_id,
    NULL,
    NULL,
    ((x.rn - 1) % 5) + 1 AS day_of_week,
    CASE FLOOR((x.rn - 1) / 5) % 4
        WHEN 0 THEN '07:30:00'
        WHEN 1 THEN '09:30:00'
        WHEN 2 THEN '13:00:00'
        ELSE '15:00:00'
    END AS start_time,
    CASE FLOOR((x.rn - 1) / 5) % 4
        WHEN 0 THEN '09:00:00'
        WHEN 1 THEN '11:00:00'
        WHEN 2 THEN '14:30:00'
        ELSE '16:30:00'
    END AS end_time,
    CASE WHEN COALESCE(x.lab_units, 0) > 0 THEN 'Mixed' ELSE 'Lecture' END AS schedule_type,
    'OPEN'
FROM (
    SELECT
        cs.section_id,
        c.lab_units,
        ROW_NUMBER() OVER (
            PARTITION BY cs.term_id, cs.section_code
            ORDER BY c.course_code
        ) AS rn
    FROM class_sections cs
    JOIN courses c ON c.course_id = cs.course_id
    WHERE cs.section_code LIKE 'BSN-%'
) x
WHERE NOT EXISTS (
    SELECT 1
    FROM class_schedules sch
    WHERE sch.section_id = x.section_id
);

-- Summary: BSN sections and schedules per calendar term.
SELECT at.term_code, at.term_name,
       COUNT(DISTINCT cs.section_id) AS bsn_sections,
       COUNT(DISTINCT sch.schedule_id) AS bsn_schedules
FROM academic_terms at
LEFT JOIN class_sections cs
    ON cs.term_id = at.term_id
   AND cs.section_code LIKE 'BSN-%'
LEFT JOIN class_schedules sch
    ON sch.section_id = cs.section_id
WHERE at.term_code REGEXP '^[12]1[0-9]{8}$'
GROUP BY at.term_id, at.term_code, at.term_name
ORDER BY at.term_code;

-- Curriculum term slices expected during block enlistment.
SELECT cc.year_level, cc.semester_number, COUNT(*) AS subjects, SUM(c.credit_units) AS units
FROM curriculum_courses cc
JOIN curriculum_templates ct ON ct.curriculum_id = cc.curriculum_id
JOIN programs p ON p.program_id = ct.program_id
JOIN courses c ON c.course_id = cc.course_id
WHERE p.program_code = 'BSN'
  AND ct.is_active = 1
GROUP BY cc.year_level, cc.semester_number
ORDER BY cc.year_level, cc.semester_number;
-- =============================================================================
-- FINANCE DEMO PERSONAS — fresh seed for Jun 2026 billing QA
-- Run AFTER: 00_fresh_demo_bootstrap + 00_bsit_full_align + seed_program_fees
-- Run AFTER: 00_finance_demo_reset.sql
-- Password (all): 1234
--
-- Personas:
--   2026-0028 Juan Dela Cruz  — Student Manager add/drop, clean current term
--   2026-0027 John Doe        — forward PHP 100, pay PHP 1 → net PHP 99
--   2026-0026 Jane TermTest    — Y1 S2 unpaid balance before term transition
-- =============================================================================
USE eacdb;
SET NAMES utf8mb4 COLLATE utf8mb4_general_ci;

SET @pwd = '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EhsLkT/Oh.reShMkwpfpJ2';

-- ── Open registrar term: A.Y. 2025-2026 2nd Sem (Y2 S2 demo window) ─────────
SET @open_db  = '2120252026';
SET @open_sl  = 'SL_2220252026';
SET @open_tid = (SELECT term_id FROM academic_terms WHERE term_code = @open_db LIMIT 1);

UPDATE academic_terms SET is_active = 0, status = 'INACTIVE';
UPDATE academic_terms SET is_active = 1, status = 'ACTIVE' WHERE term_code = @open_db;
UPDATE system_settings SET setting_value = @open_db WHERE setting_key = 'CURRENT_ACADEMIC_TERM';

-- Pick one Y2 S2 BSIT block section (first curriculum course on BSIT-2-2-A)
SET @sec_y2s2 = (
    SELECT cs.section_id
    FROM class_sections cs
    JOIN courses c ON c.course_id = cs.course_id
    JOIN curriculum_courses cc ON cc.course_id = c.course_id
    JOIN curriculum_templates ct ON ct.curriculum_id = cc.curriculum_id AND ct.is_active = 1
    JOIN programs p ON p.program_id = ct.program_id
    WHERE p.program_code = 'BSIT'
      AND cs.term_id = @open_tid
      AND cs.section_code = 'BSIT-2-2-A'
      AND cc.year_level = 2 AND cc.semester_number = 2
    ORDER BY c.course_code
    LIMIT 1
);

-- ── Helper: Juan & John (Y2 S2, ENROLLED, 1 subject) ─────────────────────────
-- 2026-0028 Juan Dela Cruz
SET @sn = '2026-0028';
INSERT INTO applicants (reference_number, first_name, last_name, email, program1, applicant_status, term_year, created_at, updated_at)
VALUES ('DEMO-FIN-0028', 'Juan', 'Dela Cruz', 'juan.delacruz@example.com', 'BSIT', 'ENROLLED', @open_sl, NOW(), NOW());
INSERT INTO sys_users (username, password, real_name, first_name, last_name, role, program_code, year_level, semester, term_year,
    reference_number, student_type, admission_status, is_active, status)
VALUES (@sn, @pwd, 'Juan Dela Cruz', 'Juan', 'Dela Cruz', 'Student', 'BSIT', 2, 2, @open_sl,
    'DEMO-FIN-0028', 'Continuing', 'ENROLLED', 1, 'ACTIVE');
INSERT INTO students (student_number, user_id, reference_number, first_name, last_name, real_name, email, program_code,
    year_level, semester, term_year, student_type, admission_status, scholarship_type, scholarship_approved, is_active, enrollment_blocked, status, role)
SELECT @sn, user_id, 'DEMO-FIN-0028', 'Juan', 'Dela Cruz', 'Juan Dela Cruz', 'juan.delacruz@example.com', 'BSIT',
    2, 2, @open_sl, 'Continuing', 'ENROLLED', 'NONE', 0, 1, 0, 'ACTIVE', 'STUDENT'
FROM sys_users WHERE username = @sn;
INSERT INTO student_enlistments (student_id, course_id, section_id)
SELECT @sn, cs.course_id, cs.section_id FROM class_sections cs WHERE cs.section_id = @sec_y2s2;

-- 2026-0027 John Doe (+ PHP 100 forward debt)
SET @sn = '2026-0027';
INSERT INTO applicants (reference_number, first_name, last_name, email, program1, applicant_status, term_year, created_at, updated_at)
VALUES ('DEMO-FIN-0027', 'John', 'Doe', 'john.doe@example.com', 'BSIT', 'ENROLLED', @open_sl, NOW(), NOW());
INSERT INTO sys_users (username, password, real_name, first_name, last_name, role, program_code, year_level, semester, term_year,
    reference_number, student_type, admission_status, is_active, status)
VALUES (@sn, @pwd, 'John Doe', 'John', 'Doe', 'Student', 'BSIT', 2, 2, @open_sl,
    'DEMO-FIN-0027', 'Continuing', 'ENROLLED', 1, 'ACTIVE');
INSERT INTO students (student_number, user_id, reference_number, first_name, last_name, real_name, email, program_code,
    year_level, semester, term_year, student_type, admission_status, scholarship_type, scholarship_approved, is_active, enrollment_blocked, status, role)
SELECT @sn, user_id, 'DEMO-FIN-0027', 'John', 'Doe', 'John Doe', 'john.doe@example.com', 'BSIT',
    2, 2, @open_sl, 'Continuing', 'ENROLLED', 'NONE', 0, 1, 0, 'ACTIVE', 'STUDENT'
FROM sys_users WHERE username = @sn;
INSERT INTO student_enlistments (student_id, course_id, section_id)
SELECT @sn, cs.course_id, cs.section_id FROM class_sections cs WHERE cs.section_id = @sec_y2s2;
INSERT INTO student_ledger (student_id, transaction_type, description, debit, credit)
VALUES (@sn, 'FORWARDED_BALANCE', 'Balance forwarded from previous term (demo seed)', 100.00, 0);

-- ── 2026-0026 Jane TermTest — Y1 S2 before term transition ───────────────────
SET @y1s2_db  = '2120242025';
SET @y1s2_sl  = 'SL_2120242025';
SET @y1s2_tid = (SELECT term_id FROM academic_terms WHERE term_code = @y1s2_db LIMIT 1);
SET @sec_y1s2 = (
    SELECT cs.section_id FROM class_sections cs
    JOIN curriculum_courses cc ON cc.course_id = cs.course_id
    JOIN curriculum_templates ct ON ct.curriculum_id = cc.curriculum_id AND ct.is_active = 1
    JOIN programs p ON p.program_id = ct.program_id
    WHERE p.program_code = 'BSIT' AND cs.term_id = @y1s2_tid AND cs.section_code = 'BSIT-1-2-A'
      AND cc.year_level = 1 AND cc.semester_number = 2
    ORDER BY cs.section_id LIMIT 1
);

SET @sn = '2026-0026';
INSERT INTO applicants (reference_number, first_name, last_name, email, program1, applicant_status, term_year, created_at, updated_at)
VALUES ('DEMO-FIN-0026', 'Jane', 'TermTest', 'jane.termtest@example.com', 'BSIT', 'ENROLLED', @y1s2_sl, NOW(), NOW());
INSERT INTO sys_users (username, password, real_name, first_name, last_name, role, program_code, year_level, semester, term_year,
    reference_number, student_type, admission_status, is_active, status)
VALUES (@sn, @pwd, 'Jane TermTest', 'Jane', 'TermTest', 'Student', 'BSIT', 1, 2, @y1s2_sl,
    'DEMO-FIN-0026', 'Regular', 'ENROLLED', 1, 'ACTIVE');
INSERT INTO students (student_number, user_id, reference_number, first_name, last_name, real_name, email, program_code,
    year_level, semester, term_year, student_type, admission_status, scholarship_type, scholarship_approved, is_active, enrollment_blocked, status, role)
SELECT @sn, user_id, 'DEMO-FIN-0026', 'Jane', 'TermTest', 'Jane TermTest', 'jane.termtest@example.com', 'BSIT',
    1, 2, @y1s2_sl, 'Regular', 'ENROLLED', 'NONE', 0, 1, 0, 'ACTIVE', 'STUDENT'
FROM sys_users WHERE username = @sn;
INSERT INTO student_enlistments (student_id, course_id, section_id)
SELECT @sn, cs.course_id, cs.section_id FROM class_sections cs WHERE cs.section_id = @sec_y1s2;

-- Y1 S2 assessment (matches demo scenario: total 56074, paid 3000 → forward debt 53074)
INSERT INTO student_ledger (student_id, transaction_type, description, debit, credit) VALUES
(@sn, 'TUITION_ASSESSMENT', 'Tuition Fee Assessment (demo Y1 S2 block)', 30000.00, 0),
(@sn, 'MISC_ASSESSMENT',    'Miscellaneous Fees', 8952.00, 0),
(@sn, 'OTHER_ASSESSMENT',   'Other Fees', 17122.00, 0);

INSERT INTO payments (transaction_id, or_number, reference_number, amount, payment_method, semester, year_level, term_year, remarks, payment_date, status)
VALUES ('DEMO-0026-DP', 'OR-0026-01', @sn, 3000.00, 'CASH', 2, 1, @y1s2_sl, 'Demo Y1 S2 partial payment', NOW(), 'COMPLETED');
INSERT INTO student_ledger (student_id, transaction_type, description, debit, credit)
VALUES (@sn, 'PAYMENT', 'Demo Y1 S2 partial payment', 0, 3000.00);

-- ── Summary ───────────────────────────────────────────────────────────────────
SELECT student_number, real_name, year_level, semester, term_year, admission_status
FROM students
WHERE student_number IN ('2026-0026','2026-0027','2026-0028')
ORDER BY student_number;

SELECT student_id,
       COALESCE(SUM(debit),0) - COALESCE(SUM(credit),0) AS net_forwarded
FROM student_ledger
WHERE student_id IN ('2026-0026','2026-0027','2026-0028')
  AND transaction_type = 'FORWARDED_BALANCE'
GROUP BY student_id;

SELECT 'Open term' AS label, setting_value AS current_db_term
FROM system_settings WHERE setting_key = 'CURRENT_ACADEMIC_TERM';
