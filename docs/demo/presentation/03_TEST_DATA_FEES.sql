USE eacdb;

-- 1. SEED GLOBAL FALLBACK TEMPLATES (term_id = NULL)
INSERT INTO `program_fee_settings` 
(`program_id`, `term_id`, `year_level`, `semester_number`, `fee_tuition_per_unit`, `fee_lec_per_unit`, `fee_misc_library`, `fee_misc_id`) 
VALUES 
(1, NULL, 1, 1, 1500.00, 1500.00, 2000.00, 350.00), -- BSIT Year 1, Sem 1
(1, NULL, 1, 2, 1500.00, 1500.00, 2000.00, 0.00),   -- BSIT Year 1, Sem 2 (No ID fee in 2nd sem)
(2, NULL, 1, 1, 1600.00, 1600.00, 2500.00, 350.00); -- BSCS Year 1, Sem 1

-- 2. SEED TERM 10 DATA
INSERT INTO `program_fee_settings` 
(`program_id`, `term_id`, `year_level`, `semester_number`, `fee_tuition_per_unit`, `fee_lec_per_unit`, `fee_misc_library`, `fee_misc_id`) 
VALUES 
(1, 10, 1, 1, 1550.00, 1550.00, 2000.00, 350.00), -- BSIT Year 1, Sem 1 (Inflation: 1550)
(1, 10, 1, 2, 1550.00, 1550.00, 2000.00, 0.00),   -- BSIT Year 1, Sem 2 (Inflation: 1550)
(2, 10, 1, 1, 1650.00, 1650.00, 2500.00, 350.00); -- BSCS Year 1, Sem 1 (Inflation: 1650)

-- 3. SEED ADMISSION APPLICATIONS
-- Test the admission-to-enrollment workflow.
INSERT INTO `admission_applications` (`applicant_id`, `full_name`, `status`) VALUES 
('APP-2026-0001', 'John Doe', 'PENDING'),
('APP-2026-0002', 'Jane Smith', 'ACCEPTED');
