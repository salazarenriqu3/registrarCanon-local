-- ==============================================================================
-- BSIT FULL LIFECYCLE TEST SEED
-- ==============================================================================
-- Run this script to generate all necessary data to test a student moving
-- from Applicant -> 1st Year -> 4th Year.
-- ==============================================================================

USE registrar_sandbox; -- Or your target DB (eacdb)

-- 1. Ensure 4 Years of Academic Terms Exist (8 Semesters)
INSERT IGNORE INTO academic_terms (term_code, term_name, start_date, end_date, status, is_active) VALUES
('1120242025', '1st Semester 2024-2025', '2024-08-01', '2024-12-15', 'ACTIVE', 1),
('2120242025', '2nd Semester 2024-2025', '2025-01-15', '2025-05-30', 'INACTIVE', 0),
('1120252026', '1st Semester 2025-2026', '2025-08-01', '2025-12-15', 'INACTIVE', 0),
('2120252026', '2nd Semester 2025-2026', '2026-01-15', '2026-05-30', 'INACTIVE', 0),
('1120262027', '1st Semester 2026-2027', '2026-08-01', '2026-12-15', 'INACTIVE', 0),
('2120262027', '2nd Semester 2026-2027', '2027-01-15', '2027-05-30', 'INACTIVE', 0),
('1120272028', '1st Semester 2027-2028', '2027-08-01', '2027-12-15', 'INACTIVE', 0),
('2120272028', '2nd Semester 2027-2028', '2028-01-15', '2028-05-30', 'INACTIVE', 0);

-- Set active term to 1120242025 just in case
UPDATE academic_terms SET is_active = 0, status = 'INACTIVE';
UPDATE academic_terms SET is_active = 1, status = 'ACTIVE' WHERE term_code = '1120242025';

-- 2. Clean up previous test runs for this applicant and recreate
DELETE FROM applicant_payments WHERE applicant_id = 'REF-BSIT-LIFE';
DELETE FROM payments WHERE reference_number = 'REF-BSIT-LIFE';
DELETE FROM applicants WHERE reference_number = 'REF-BSIT-LIFE';

INSERT INTO applicants (reference_number, first_name, last_name, email, program1, applicant_status, term_year)
VALUES ('REF-BSIT-LIFE', 'Lifecycle', 'Tester', 'lifecycle@example.com', 'BSIT', 'Pending', '1120242025');

-- 3. Set Up Program Fee Settings (Global Fallback - NULL term) for all 4 years of BSIT
SET @prog_id = (SELECT program_id FROM programs WHERE program_code = 'BSIT' LIMIT 1);

-- Clean old fee settings for BSIT to ensure clean test
DELETE FROM program_fee_settings WHERE program_id = @prog_id;

-- 1st Year Fees
INSERT INTO program_fee_settings (program_id, year_level, semester_number, term_id, fee_tuition_per_unit, fee_misc_registration, fee_misc_library, fee_misc_medical, is_active)
VALUES 
(@prog_id, 1, 1, NULL, 1500.00, 500.00, 300.00, 200.00, 1),
(@prog_id, 1, 2, NULL, 1500.00, 500.00, 300.00, 200.00, 1),
-- 2nd Year Fees
(@prog_id, 2, 1, NULL, 1600.00, 500.00, 300.00, 200.00, 1),
(@prog_id, 2, 2, NULL, 1600.00, 500.00, 300.00, 200.00, 1),
-- 3rd Year Fees (Add Computer Lab Fee)
(@prog_id, 3, 1, NULL, 1700.00, 500.00, 300.00, 200.00, 1),
(@prog_id, 3, 2, NULL, 1700.00, 500.00, 300.00, 200.00, 1),
-- 4th Year Fees (Add OJT / Capstone Fees)
(@prog_id, 4, 1, NULL, 1800.00, 500.00, 300.00, 200.00, 1),
(@prog_id, 4, 2, NULL, 1800.00, 500.00, 300.00, 200.00, 1);

UPDATE program_fee_settings SET fee_lab_per_unit = 1000.00 WHERE program_id = @prog_id AND year_level = 3;
UPDATE program_fee_settings SET fee_other_dev = 2000.00 WHERE program_id = @prog_id AND year_level = 4;

-- 4. Generate Class Sections for the entire BSIT Curriculum across the 8 terms
-- We map Year 1, Sem 1 -> 2425-1, etc.
-- This allows the user to just enlist without having to create sections first.

SET @curr_id = (
    SELECT ct.curriculum_id FROM curriculum_templates ct 
    JOIN programs p ON ct.program_id = p.program_id 
    WHERE p.program_code = 'BSIT' AND ct.is_active = 1 LIMIT 1
);

-- Delete existing generated sections for this test to avoid dupes
DELETE FROM class_sections WHERE section_code LIKE 'BSIT-LIFE-%';

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
INSERT INTO class_sections (term_id, course_id, section_code, max_capacity, section_status)
SELECT 
    t.term_id,
    cc.course_id,
    CONCAT('BSIT-LIFE-', cc.year_level, cc.semester_number),
    40,
    'OPEN'
FROM curriculum_courses cc
JOIN lifecycle_term_map ltm ON cc.year_level = ltm.year_level AND cc.semester_number = ltm.semester_number
JOIN academic_terms t ON t.term_code = ltm.term_code
WHERE cc.curriculum_id = @curr_id;

SELECT 'Test data successfully generated! Applicant REF-BSIT-LIFE is ready.' AS Result;
