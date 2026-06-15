-- =============================================================================
-- Marian School of Nursing — BSN Official Curriculum (Effective S.Y. 2024-2025)
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

-- Year 1 — First Semester (9 subjects / 28 units)
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

-- Year 1 — Second Semester (8 subjects / 27 units)
INSERT INTO bsn_curriculum_staging VALUES
('AET0 12', 'Ethics', 1, 2, 3, 0),
('ANS2 12', 'CWTS 2/LTS 2/ROTC 2', 1, 2, 3, 0),
('APC0 12', 'Purposive Communication', 1, 2, 3, 0),
('MMP0421', 'Microbiology and Parasitology', 1, 2, 3, 1),
('NCM1A12', 'Fundamentals of Nursing Practice', 1, 2, 3, 2),
('NHA0512', 'Health Assessment', 1, 2, 3, 2),
('NHE0 23', 'Health Education', 1, 2, 3, 0),
('PE2 12', 'PE 2 (PATHFit 2): Exercise-based Fitness Activities', 1, 2, 2, 0);

-- Year 2 — First Semester (7 subjects / 29 units)
INSERT INTO bsn_curriculum_staging VALUES
('AHU2 21', 'Arts and Humanities', 2, 1, 3, 0),
('ASS6 21', 'Life, Works and Writings of Rizal', 2, 1, 3, 0),
('NCHN1', 'Community Health Nursing 1', 2, 1, 2, 2),
('NCM721', 'Care of Mother, Child, Adolescent (Well Clients)', 2, 1, 4, 5),
('NND021', 'Nutrition and Diet Therapy', 2, 1, 2, 1),
('NPH0 22', 'Pharmacology', 2, 1, 3, 0),
('PE3 21', 'PE 3 (PATHFit 3): Basic Swimming', 2, 1, 2, 0);

-- Year 2 — Second Semester (6 subjects / 26 units)
INSERT INTO bsn_curriculum_staging VALUES
('NCM922', 'Care of Mother, Child at Risk or with Problems (Acute and Chronic)', 2, 2, 6, 6),
('NET0 22', 'Health Care Ethics (Bioethics)', 2, 2, 3, 0),
('PE4 22', 'PE 4 (PATHFit 4): Advance Swimming', 2, 2, 2, 0),
('SMA3021', 'Biostatistics', 2, 2, 3, 0),
('STS0 22', 'Science, Technology and Society', 2, 2, 3, 0),
('UCO211', 'Nursing Informatics', 2, 2, 2, 1);

-- Year 3 — First Semester (4 subjects / 25 units)
INSERT INTO bsn_curriculum_staging VALUES
('AHU1 11', 'Art Appreciation', 3, 1, 3, 0),
('ASS1011', 'Social Science and Philosophy', 3, 1, 3, 0),
('NCM831', 'Care of Clients with Problems in Oxygenation, Fluid and Electrolytes, Infectious, Inflammatory and Immunologic Response, Cellular Aberrations, Acute and Chronic', 3, 1, 8, 6),
('NRES131', 'Nursing Research 1', 3, 1, 2, 3);

-- Year 3 — Second Semester (6 subjects / 26 units)
INSERT INTO bsn_curriculum_staging VALUES
('ACW0 12', 'The Contemporary World', 3, 2, 3, 0),
('NCHN2', 'Community Health Nursing 2', 3, 2, 2, 1),
('NCM1432', 'Care of Older Adult', 3, 2, 2, 1),
('NCM1632', 'Care of Clients with Problems in Nutrition, Gastrointestinal, Metabolism and Endocrine, Perception and Coordination (Acute and Chronic)', 3, 2, 5, 4),
('NRES232', 'Nursing Research 2', 3, 2, 0, 2),
('SMST012', 'Mathematics Science and Technology', 3, 2, 3, 0);

-- Year 4 — First Semester (3 subjects / 21 units)
INSERT INTO bsn_curriculum_staging VALUES
('NCM117', 'Care of Clients with Maladaptive Patterns of Behavior, Acute and Chronic', 4, 1, 4, 4),
('NCM118', 'Nursing Care of Clients with Life Threatening Conditions/Acutely Ill/Multi-organ Problems, High Acuity and Emergency Situation, Acute and Chronic', 4, 1, 4, 5),
('NCM7A41', 'Nursing Leadership and Management A', 4, 1, 4, 0);

-- Year 4 — Second Semester (4 subjects / 20 units)
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
