-- =============================================================================
-- BSIT FULL ALIGNMENT — terms + official curriculum + class sections
--
-- Aligns eacdb with enrollment/registrar TermParserUtil:
--   DB term_code:     {semester}1{AY_start}{AY_end}   e.g. 2120242025
--   Student term_year: SL_{sem}{yearLevel}{years}   e.g. SL_2120242025 (Y1, 2nd sem)
--
-- Run entire file once in MySQL Workbench (Execute All) on database eacdb.
-- Safe to re-run: upserts terms/courses; sections use NOT EXISTS guards.
-- Does NOT delete grades or enlistments. Does NOT force ACTIVE on any term.
--
-- After run (optional — adjust to your open term / demo student):
--   UPDATE system_settings SET setting_value = 'SL_2120242025'
--     WHERE setting_key = 'CURRENT_ACADEMIC_TERM';
--   UPDATE students SET term_year = 'SL_2120242025', year_level = 1, semester = 2
--     WHERE student_number = '2026-0004';
-- =============================================================================
USE eacdb;

-- =============================================================================
-- PART 1 — Calendar academic terms (2024-2025 … 2027-2028)
-- =============================================================================

UPDATE academic_terms
SET status = 'INACTIVE',
    is_active = 0
WHERE term_code REGEXP '^[12][2-4][0-9]{8}$';

INSERT INTO academic_terms
    (term_code, term_name, academic_year, semester_number, start_date, end_date, status, is_active)
VALUES
    ('1120242025', 'A.Y. 2024-2025 - 1st Semester', '2024-2025', 1, '2024-08-01', '2024-12-15', 'INACTIVE', 0),
    ('2120242025', 'A.Y. 2024-2025 - 2nd Semester', '2024-2025', 2, '2025-01-15', '2025-05-30', 'INACTIVE', 0),
    ('1120252026', 'A.Y. 2025-2026 - 1st Semester', '2025-2026', 1, '2025-08-01', '2025-12-15', 'INACTIVE', 0),
    ('2120252026', 'A.Y. 2025-2026 - 2nd Semester', '2025-2026', 2, '2026-01-15', '2026-05-30', 'INACTIVE', 0),
    ('1120262027', 'A.Y. 2026-2027 - 1st Semester', '2026-2027', 1, '2026-08-01', '2026-12-15', 'INACTIVE', 0),
    ('2120262027', 'A.Y. 2026-2027 - 2nd Semester', '2026-2027', 2, '2027-01-15', '2027-05-30', 'INACTIVE', 0),
    ('1120272028', 'A.Y. 2027-2028 - 1st Semester', '2027-2028', 1, '2027-08-01', '2027-12-15', 'INACTIVE', 0),
    ('2120272028', 'A.Y. 2027-2028 - 2nd Semester', '2027-2028', 2, '2028-01-15', '2028-05-30', 'INACTIVE', 0)
ON DUPLICATE KEY UPDATE
    term_name = VALUES(term_name),
    academic_year = VALUES(academic_year),
    semester_number = VALUES(semester_number),
    start_date = VALUES(start_date),
    end_date = VALUES(end_date);

-- If CURRENT_ACADEMIC_TERM is SL_* and a matching calendar row exists, store canonical DB code
UPDATE system_settings ss
SET setting_value = CONCAT(
        SUBSTRING(ss.setting_value, 4, 1), '1',
        SUBSTRING(ss.setting_value, 6, 4),
        SUBSTRING(ss.setting_value, 10, 4)
    )
WHERE ss.setting_key = 'CURRENT_ACADEMIC_TERM'
  AND ss.setting_value LIKE 'SL\_%'
  AND LENGTH(ss.setting_value) >= 13
  AND EXISTS (
      SELECT 1 FROM academic_terms at
      WHERE at.term_code = CONCAT(
          SUBSTRING(ss.setting_value, 4, 1), '1',
          SUBSTRING(ss.setting_value, 6, 4),
          SUBSTRING(ss.setting_value, 10, 4)
      )
  );

-- =============================================================================
-- PART 2 — SET BSIT official curriculum (48 courses, S.Y. 2024-2025)
-- Source: SET BSIT.docx
-- =============================================================================

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
      SELECT 1 FROM curriculum_templates ct2 WHERE ct2.program_id = p.program_id
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

-- Y1S1 (10)
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

-- Y1S2 (8)
INSERT INTO bsit_curriculum_staging VALUES
('ACW0 12',  'The Contemporary World',                              1, 2, 3, 0),
('APC0 12',  'Purposive Communication',                             1, 2, 3, 0),
('AET0 12',  'Ethics',                                              1, 2, 3, 0),
('SMST012',  'Mathematics, Science & Technology',                   1, 2, 3, 0),
('PE2 12',   'PE 2 (PATHFit 2): Exercise-based Fitness Activities', 1, 2, 2, 0),
('ANS2 12',  'CWTS 2/LTS 2/ROTC 2',                                 1, 2, 3, 0),
('UHC1 11',  'Introduction to Human Computer Interaction',          1, 2, 2, 1),
('UPR2 12',  'Advanced Problem Solving & Programming',              1, 2, 2, 1);

-- Y2S1 (7)
INSERT INTO bsit_curriculum_staging VALUES
('AHU2 21',  'Arts and Humanities',                                 2, 1, 3, 0),
('ASS6 21',  'Life, Works & Writing of Rizal',                    2, 1, 3, 0),
('PE3 21',   'PE 3 (PATHFit 3): Basic Swimming',                    2, 1, 2, 0),
('BEC0 12',  'Accounting Principles',                               2, 1, 3, 0),
('UPR3 21',  'Object Oriented Programming',                         2, 1, 2, 1),
('UDM0 21',  'Discrete Mathematics',                                2, 1, 3, 0),
('UIM0 12',  'Introduction to Information Management',              2, 1, 2, 1);

-- Y2S2 (6)
INSERT INTO bsit_curriculum_staging VALUES
('STS0 22',  'Science, Technology & Society',                       2, 2, 3, 0),
('PE4 22',   'PE 4 (PATHFit 4): Advance Swimming',                  2, 2, 2, 0),
('AEN4 22',  'Business Correspondence',                             2, 2, 3, 0),
('UNW122',   'Networking 1',                                        2, 2, 2, 1),
('UDS022',   'Data Structures and Algorithms',                      2, 2, 2, 1),
('UDB122',   'Database Management System 1',                        2, 2, 2, 1);

-- Y3S1 (6)
INSERT INTO bsit_curriculum_staging VALUES
('SMA3 21',  'Statistics',                                          3, 1, 3, 0),
('USI1 31',  'System Integration and Architecture 1',               3, 1, 2, 1),
('UNW2 31',  'Networking 2',                                        3, 1, 2, 1),
('UEL2 31',  'Tangible Technologies',                               3, 1, 2, 1),
('UEL131',   'Intangible Technologies',                               3, 1, 2, 1),
('UDB231',   'Advanced Database Systems',                           3, 1, 2, 1);

-- Y3S2 (5)
INSERT INTO bsit_curriculum_staging VALUES
('UADET 32', 'Application Development and Emerging Technologies',     3, 2, 2, 1),
('UEDP0 32', 'Event Driven Programming',                            3, 2, 2, 1),
('UIAS1 32', 'Information Assurance and Security 1',                3, 2, 2, 1),
('UQM0 32',  'Quantitative Methods',                                3, 2, 3, 0),
('USPI 32',  'Social and Professional Issues',                      3, 2, 3, 0);

-- Y4S1 (4)
INSERT INTO bsit_curriculum_staging VALUES
('UCP1 41',  'Capstone Project 1',                                  4, 1, 3, 0),
('UIAS2 41', 'Information Assurance and Security 2',                4, 1, 2, 1),
('USAM0 41', 'Systems Administration and Maintenance',                4, 1, 2, 1),
('USI1 41',  'System Integration and Architecture 2',               4, 1, 2, 1);

-- Y4S2 (2)
INSERT INTO bsit_curriculum_staging VALUES
('UCP2 42',  'Capstone Project 2',                                  4, 2, 3, 0),
('UOJT 42',  'On the Job Training',                                 4, 2, 9, 0);

INSERT INTO courses (
    course_code, course_title, department_id, credit_units,
    lec_units, lab_units, lecture_hours_per_week, lab_hours_per_week,
    course_type, active_status, onlist
)
SELECT
    s.course_code, s.course_title, @dept_id,
    s.lec_units + s.lab_units, s.lec_units, s.lab_units,
    s.lec_units, s.lab_units,
    IF(s.lab_units > 0, 'Mixed', 'Lecture'), 1, 1
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

INSERT INTO courses (
    course_code, course_title, department_id, credit_units,
    lec_units, lab_units, lecture_hours_per_week, lab_hours_per_week,
    course_type, active_status, onlist
)
SELECT 'AEC0 11', 'Emilian Culture', @dept_id, 1, 1, 0, 1, 0, 'Lecture', 1, 1
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM courses WHERE course_code = 'AEC0 11')
ON DUPLICATE KEY UPDATE course_title = 'Emilian Culture', active_status = 1, onlist = 1;

DELETE FROM curriculum_courses WHERE curriculum_id = @curriculum_id;

INSERT INTO curriculum_courses (curriculum_id, course_id, year_level, semester_number, is_required)
SELECT @curriculum_id, c.course_id, s.year_level, s.semester_number, 1
FROM bsit_curriculum_staging s
JOIN courses c ON c.course_code = s.course_code;

DROP TEMPORARY TABLE IF EXISTS bsit_curriculum_staging;

-- =============================================================================
-- PART 3 — Legacy BSCS-clone cleanup (off-list old IT/CC/GE codes)
-- =============================================================================

UPDATE courses SET course_code = 'AECO 11', course_title = 'Emilian Culture', active_status = 1
WHERE course_code IN ('AFCO 11', 'AFC0 11')
  AND NOT EXISTS (
      SELECT 1 FROM courses c2 WHERE c2.course_code = 'AECO 11' AND c2.course_id <> courses.course_id
  );

DELETE cc FROM curriculum_courses cc
WHERE cc.year_level IS NULL OR cc.semester_number IS NULL;

UPDATE courses
SET active_status = 0, onlist = 0
WHERE course_code IN (
    'CC101', 'CC102', 'CC103', 'IT104',
    'GE101', 'GE102', 'GE103',
    'IT111', 'IT112', 'IT121', 'IT122',
    'IT211', 'IT212', 'IT221', 'IT222',
    'IT311', 'IT312', 'IT322', 'IT411', 'IT412', 'IT421', 'IT422',
    'NSTP101', 'PE101'
);

-- Re-assert official SET codes stay on-list
UPDATE courses c
JOIN curriculum_courses cc ON cc.course_id = c.course_id
JOIN curriculum_templates ct ON ct.curriculum_id = cc.curriculum_id
JOIN programs p ON p.program_id = ct.program_id
SET c.active_status = 1, c.onlist = 1
WHERE p.program_code = 'BSIT' AND ct.curriculum_id = @curriculum_id;

-- =============================================================================
-- PART 4 — Class sections (BSIT-{Y}-{S}-A on every calendar term; Y1 also -B)
-- =============================================================================

INSERT INTO class_sections (course_id, term_id, section_code, max_capacity, section_status, semester_number)
SELECT DISTINCT
    c.course_id, at.term_id,
    CONCAT('BSIT-', cc.year_level, '-', cc.semester_number, '-A'),
    40, 'Open', cc.semester_number
FROM curriculum_courses cc
JOIN curriculum_templates ct ON cc.curriculum_id = ct.curriculum_id
JOIN programs p ON ct.program_id = p.program_id
JOIN courses c ON cc.course_id = c.course_id
JOIN academic_terms at
    ON at.term_code REGEXP '^[12]1[0-9]{8}$'
   AND at.semester_number = cc.semester_number
WHERE p.program_code = 'BSIT'
  AND ct.is_active = 1
  AND ct.curriculum_id = @curriculum_id
  AND COALESCE(c.onlist, 1) = 1
  AND NOT EXISTS (
      SELECT 1 FROM class_sections cs
      WHERE cs.course_id = c.course_id AND cs.term_id = at.term_id
        AND cs.section_code = CONCAT('BSIT-', cc.year_level, '-', cc.semester_number, '-A')
  );

INSERT INTO class_sections (course_id, term_id, section_code, max_capacity, section_status, semester_number)
SELECT DISTINCT
    c.course_id, at.term_id,
    CONCAT('BSIT-', cc.year_level, '-', cc.semester_number, '-B'),
    40, 'Open', cc.semester_number
FROM curriculum_courses cc
JOIN curriculum_templates ct ON cc.curriculum_id = ct.curriculum_id
JOIN programs p ON ct.program_id = p.program_id
JOIN courses c ON cc.course_id = c.course_id
JOIN academic_terms at
    ON at.term_code REGEXP '^[12]1[0-9]{8}$'
   AND at.semester_number = cc.semester_number
WHERE p.program_code = 'BSIT'
  AND ct.is_active = 1
  AND ct.curriculum_id = @curriculum_id
  AND cc.year_level = 1
  AND cc.semester_number IN (1, 2)
  AND COALESCE(c.onlist, 1) = 1
  AND NOT EXISTS (
      SELECT 1 FROM class_sections cs
      WHERE cs.course_id = c.course_id AND cs.term_id = at.term_id
        AND cs.section_code = CONCAT('BSIT-', cc.year_level, '-', cc.semester_number, '-B')
  );

-- =============================================================================
-- PART 5 — Verification summaries
-- =============================================================================

SELECT '--- Calendar terms ---' AS report_section;
SELECT term_id, term_code, term_name, academic_year, semester_number, status, is_active
FROM academic_terms
WHERE term_code REGEXP '^[12]1[0-9]{8}$'
ORDER BY term_code;

SELECT '--- BSIT curriculum by year/sem (expect 10,8,7,6,6,5,4,2) ---' AS report_section;
SELECT cc.year_level, cc.semester_number, COUNT(*) AS subjects
FROM curriculum_courses cc
WHERE cc.curriculum_id = @curriculum_id
GROUP BY cc.year_level, cc.semester_number
ORDER BY cc.year_level, cc.semester_number;

SELECT '--- BSIT sections per calendar term ---' AS report_section;
SELECT at.term_code, at.term_name, COUNT(DISTINCT cs.section_id) AS bsit_sections
FROM academic_terms at
LEFT JOIN class_sections cs ON cs.term_id = at.term_id AND cs.section_code LIKE 'BSIT-%'
WHERE at.term_code REGEXP '^[12]1[0-9]{8}$'
GROUP BY at.term_id, at.term_code, at.term_name
ORDER BY at.term_code;

SET @open = (SELECT setting_value FROM system_settings WHERE setting_key = 'CURRENT_ACADEMIC_TERM' LIMIT 1);
SET @open_db = IF(
    @open LIKE 'SL\_%' AND LENGTH(@open) >= 13,
    CONCAT(SUBSTRING(@open, 4, 1), '1', SUBSTRING(@open, 6, 4), SUBSTRING(@open, 10, 4)),
    @open
);

SELECT '--- Open enrollment term (system_settings) ---' AS report_section;
SELECT @open AS current_academic_term_setting,
       @open_db AS resolved_db_term_code,
       (SELECT term_name FROM academic_terms WHERE term_code = @open_db LIMIT 1) AS resolved_term_name,
       (SELECT term_id FROM academic_terms WHERE term_code = @open_db LIMIT 1) AS resolved_term_id;

SELECT '--- Y1S2 block check (term 2120242025) ---' AS report_section;
SELECT COUNT(*) AS y1s2_open_sections
FROM class_sections cs
JOIN academic_terms at ON at.term_id = cs.term_id AND at.term_code = '2120242025'
WHERE cs.section_code LIKE 'BSIT-1-2-%'
  AND UPPER(cs.section_status) IN ('OPEN', 'ACTIVE');

-- =============================================================================
-- PART 6 — OPTIONAL: uncomment to set open term + demo student Elon (2026-0004)
-- =============================================================================
/*
UPDATE system_settings
SET setting_value = '2120242025'
WHERE setting_key = 'CURRENT_ACADEMIC_TERM';

UPDATE students
SET term_year = 'SL_2120242025', year_level = 1, semester = 2
WHERE student_number = '2026-0004';

UPDATE sys_users u
JOIN students s ON s.user_id = u.user_id
SET u.year_level = 1, u.semester = 2
WHERE s.student_number = '2026-0004';
*/

SELECT 'BSIT full alignment complete.' AS status_message, @curriculum_id AS active_bsit_curriculum_id;
