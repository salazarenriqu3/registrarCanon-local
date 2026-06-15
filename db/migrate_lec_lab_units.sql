-- ============================================================
-- MIGRATION: Add lec_units column and populate both
-- lec_units and lab_units from SET BSIT.docx / SET COE.docx
-- credit_units remains = lec_units + lab_units (total, for billing)
-- Rev. 24 May 2026
-- ============================================================
USE eacdb;
SET SQL_SAFE_UPDATES = 0;

-- 1. Add lec_units column if not exists
ALTER TABLE courses
    ADD COLUMN IF NOT EXISTS lec_units INT NOT NULL DEFAULT 0 AFTER credit_units;

-- Ensure lab_units exists too (already confirmed it does, but just in case)
ALTER TABLE courses
    ADD COLUMN IF NOT EXISTS lab_units INT NOT NULL DEFAULT 0 AFTER lec_units;

-- ── 2. Populate lec_units and lab_units ──────────────────────
-- BSIT & COE shared GE courses (0 lab)
UPDATE courses SET lec_units = 3, lab_units = 0 WHERE course_code IN (
    'AUS0 11','ARPH 11','SMMW 11','AHU1 11','ASS1011','ANS1 11',
    'ACW0 12','APC0 12','AET0 12','SMST012','ANS2 12',
    'AHU2 21','ASS6 21','BEC0 12','UDM0 21',
    'STS0 22','AEN4 22',
    'SMA3 21',
    'UQM0 32','USPI 32',
    'UCP1 41',
    'UCP2 42',
    'SMA5 21','SMA6 22','SMA7 31',
    'UEE0 22',
    'AEN6 32','UOHS 32','UMR0 32',
    'UTN1 41','UETC 41',
    'UEDA 12'
);

UPDATE courses SET lec_units = 2, lab_units = 0 WHERE course_code IN (
    'PE1 11','PE2 12','PE3 21','PE4 22',
    'UCLP0 32','UCLO0 32'
);

UPDATE courses SET lec_units = 1, lab_units = 0 WHERE course_code IN (
    'AECO 11','UCED 1 12','UFT0 52','UPD1 41'
);

UPDATE courses SET lec_units = 9, lab_units = 0 WHERE course_code = 'UOJT 42';
UPDATE courses SET lec_units = 3, lab_units = 0 WHERE course_code IN ('UOJ0 42','UEDP0 32');
UPDATE courses SET lec_units = 2, lab_units = 0 WHERE course_code IN ('UPD2 42','UCLO32');

-- BSIT: lec 2 + lab 1 courses
UPDATE courses SET lec_units = 2, lab_units = 1 WHERE course_code IN (
    'UCO1 11','UPR1 11','UHC1 11','UPR2 12',
    'UPR3 21','UIM0 12',
    'UNW122','UDS022','UDB122',
    'USI1 31','UNW2 31','UEL2 31','UEL131','UDB231',
    'UADET 32','UIAS1 32',
    'UIAS2 41','USAM0 41','USI1 41'
);

-- COE: lec 3 + lab 1 courses
UPDATE courses SET lec_units = 3, lab_units = 1 WHERE course_code IN (
    'SCH411','SPH1 12',
    'UPR4 21','UFEC21','UFEC22',
    'UDS1 12',
    'ULCD31','USD31',
    'UMC0 32','UCNS32',
    'UES0 41','UDS0 41','UCAO41'
);

-- COE: lec 2 + lab 1 courses
UPDATE courses SET lec_units = 2, lab_units = 1 WHERE course_code IN (
    'UNM0 22',
    'UML1 31','UFMS31','UFCS31','UDDC31',
    'UML2 32',
    'UML3 41','UOS0 41'
);

-- COE: pure lab (0 lec + lab)
UPDATE courses SET lec_units = 0, lab_units = 1 WHERE course_code IN ('UDR2 31','UIH0 31','UDR3 32');
UPDATE courses SET lec_units = 0, lab_units = 2 WHERE course_code = 'UPLD11';

-- ── 3. Recompute credit_units = lec_units + lab_units ────────
UPDATE courses SET credit_units = lec_units + lab_units
WHERE lec_units > 0 OR lab_units > 0;

-- Edge case: courses with no match yet (keep credit_units as is, set lec = credit, lab = 0)
UPDATE courses SET lec_units = credit_units, lab_units = 0
WHERE lec_units = 0 AND lab_units = 0 AND credit_units > 0;

-- ── 4. Verify ────────────────────────────────────────────────
SELECT
    c.course_code,
    c.course_title,
    c.lec_units,
    c.lab_units,
    c.credit_units AS total_units
FROM curriculum_courses cc
JOIN courses c ON cc.course_id = c.course_id
JOIN curriculum_templates ct ON cc.curriculum_id = ct.curriculum_id
WHERE ct.curriculum_name IN ('SET BSIT Curriculum','SET COE Curriculum')
  AND cc.year_level = 1 AND cc.semester_number = 1
ORDER BY ct.curriculum_name, c.course_code;

SET SQL_SAFE_UPDATES = 1;
