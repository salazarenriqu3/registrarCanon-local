-- ==============================================================================
-- MANUAL SEED DATA FOR TESTING CORE REGISTRAR LOGIC
-- Purpose: Pre-seeds isolated data for testing Term Fee Fallbacks, Imports,
--          and the Admissions/Enrollment pipeline.
-- ==============================================================================

-- 1. SEED PROGRAMS
-- Two basic programs to test targeting logic.
INSERT INTO `programs` (`program_id`, `program_code`, `program_name`) VALUES 
(1, 'BSIT', 'Bachelor of Science in Information Technology'),
(2, 'BSCS', 'Bachelor of Science in Computer Science');

-- 2. SEED ACADEMIC TERMS
-- Term 10 acts as the "source" term we have already prepared.
-- Term 11 acts as the "target" future term we will test imports against.
INSERT INTO `academic_terms` (`term_id`, `term_name`, `status`, `is_active`) VALUES 
(10, 'A.Y. 2025-2026 - 1st Semester', 'ACTIVE', 1),
(11, 'A.Y. 2025-2026 - 2nd Semester', 'UPCOMING', 0);

-- 3. SEED PROGRAM FEE SETTINGS
-- A) The Global Fallback Templates (term_id = NULL)
-- These are the foundational rates defined by the university.
INSERT INTO `program_fee_settings` 
(`program_id`, `term_id`, `year_level`, `semester_number`, `fee_tuition_per_unit`, `fee_lec_per_unit`, `fee_misc_library`, `fee_misc_id`) 
VALUES 
(1, NULL, 1, 1, 1500.00, 1500.00, 2000.00, 350.00), -- BSIT Year 1, Sem 1
(1, NULL, 1, 2, 1500.00, 1500.00, 2000.00, 0.00),   -- BSIT Year 1, Sem 2 (No ID fee in 2nd sem)
(2, NULL, 1, 1, 1600.00, 1600.00, 2500.00, 350.00); -- BSCS Year 1, Sem 1

-- B) The Exact Term Overrides (term_id = 10)
-- Suppose Term 10 was already prepared by the admin, but inflation hit, so tuition is slightly higher.
INSERT INTO `program_fee_settings` 
(`program_id`, `term_id`, `year_level`, `semester_number`, `fee_tuition_per_unit`, `fee_lec_per_unit`, `fee_misc_library`, `fee_misc_id`) 
VALUES 
(1, 10, 1, 1, 1550.00, 1550.00, 2000.00, 350.00), -- BSIT Year 1, Sem 1 (Inflation: 1550)
(1, 10, 1, 2, 1550.00, 1550.00, 2000.00, 0.00),   -- BSIT Year 1, Sem 2 (Inflation: 1550)
(2, 10, 1, 1, 1650.00, 1650.00, 2500.00, 350.00); -- BSCS Year 1, Sem 1 (Inflation: 1650)

-- NOTE for Demo:
-- When you test "Import Fees" from Term 10 to Term 11, the system should duplicate 
-- the three rows above, replacing `term_id` with 11.

-- 4. SEED ADMISSION APPLICATIONS
-- Test the admission-to-enrollment workflow.
INSERT INTO `admission_applications` (`applicant_id`, `full_name`, `status`) VALUES 
('APP-2026-0001', 'John Doe', 'PENDING'),
('APP-2026-0002', 'Jane Smith', 'ACCEPTED');

-- 5. SEED STUDENTS
-- Test billing and ledger generation logic.
INSERT INTO `students` (`student_number`, `first_name`, `last_name`, `program_code`, `year_level`, `semester`, `status`) VALUES 
('2026-0001', 'Mark', 'Zuckerberg', 'BSIT', 1, 1, 'ACTIVE'),
('2026-0002', 'Elon', 'Musk', 'BSCS', 1, 1, 'ACTIVE');

-- 6. SEED STUDENT LEDGER
-- Provide a starting balance line for a student to verify fee computations stack correctly.
INSERT INTO `student_ledger` (`student_id`, `transaction_type`, `description`, `debit`, `credit`) VALUES 
('2026-0001', 'INITIAL_BALANCE', 'Carried over from previous term', 500.00, 0.00);
