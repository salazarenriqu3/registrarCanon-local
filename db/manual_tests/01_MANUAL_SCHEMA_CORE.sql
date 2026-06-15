-- ==============================================================================
-- MANUAL SCHEMA DEFINITION FOR CORE REGISTRAR LOGIC
-- Purpose: A clean, human-readable isolated schema for testing Fee Settings
--          and Enrollment Business Logic.
-- ==============================================================================

-- 1. ACADEMIC TERMS
-- Defines the temporal scopes for fees and enrollments.
DROP TABLE IF EXISTS `academic_terms`;
CREATE TABLE `academic_terms` (
    `term_id` INT AUTO_INCREMENT PRIMARY KEY,
    `term_name` VARCHAR(100) NOT NULL,
    `start_date` DATE,
    `end_date` DATE,
    `status` VARCHAR(50) DEFAULT 'UPCOMING',
    `is_active` TINYINT(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 2. PROGRAMS
-- Defines the academic programs (targets for fees).
DROP TABLE IF EXISTS `programs`;
CREATE TABLE `programs` (
    `program_id` INT AUTO_INCREMENT PRIMARY KEY,
    `program_code` VARCHAR(50) NOT NULL UNIQUE,
    `program_name` VARCHAR(255) NOT NULL,
    `department_id` INT DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 3. PROGRAM FEE SETTINGS (THE NEW WIDE-TABLE ARCHITECTURE)
-- Stores both Global Fallback Templates (term_id = NULL) and Exact Term Overrides.
DROP TABLE IF EXISTS `program_fee_settings`;
CREATE TABLE `program_fee_settings` (
    `fee_setting_id` INT AUTO_INCREMENT PRIMARY KEY,
    `program_id` INT NOT NULL,
    `term_id` INT NULL,          -- NULL means Global Fallback
    `year_level` INT NULL,
    `semester_number` INT NULL,

    -- Core Per-Unit Fees
    `fee_tuition_per_unit` DECIMAL(10,2) DEFAULT 0.00,
    `fee_lec_per_unit` DECIMAL(10,2) DEFAULT 0.00,
    `fee_lab_per_unit` DECIMAL(10,2) DEFAULT 0.00,
    `fee_comp_per_unit` DECIMAL(10,2) DEFAULT 0.00,
    `fee_rle_per_unit` DECIMAL(10,2) DEFAULT 0.00,

    -- Miscellaneous Flat Fees
    `fee_misc_registration` DECIMAL(10,2) DEFAULT 0.00,
    `fee_misc_library` DECIMAL(10,2) DEFAULT 0.00,
    `fee_misc_medical` DECIMAL(10,2) DEFAULT 0.00,
    `fee_misc_id` DECIMAL(10,2) DEFAULT 0.00,
    `fee_misc_athletic` DECIMAL(10,2) DEFAULT 0.00,
    `fee_misc_av` DECIMAL(10,2) DEFAULT 0.00,
    `fee_misc_energy` DECIMAL(10,2) DEFAULT 0.00,
    `fee_misc_cultural` DECIMAL(10,2) DEFAULT 0.00,
    `fee_misc_guidance` DECIMAL(10,2) DEFAULT 0.00,
    `fee_misc_insurance` DECIMAL(10,2) DEFAULT 0.00,
    `fee_misc_lms` DECIMAL(10,2) DEFAULT 0.00,

    -- Other Flat Fees
    `fee_other_late_enrollment` DECIMAL(10,2) DEFAULT 0.00,
    `fee_other_add_drop` DECIMAL(10,2) DEFAULT 0.00,
    `fee_other_installment` DECIMAL(10,2) DEFAULT 0.00,
    `fee_other_id` DECIMAL(10,2) DEFAULT 0.00,
    `fee_other_insurance` DECIMAL(10,2) DEFAULT 0.00,
    `fee_other_comp` DECIMAL(10,2) DEFAULT 0.00,
    `fee_other_dev` DECIMAL(10,2) DEFAULT 0.00,

    `is_active` TINYINT(1) NOT NULL DEFAULT 1,

    -- Foreign keys (Optional in raw tests, but good for structure)
    CONSTRAINT `fk_pfs_program` FOREIGN KEY (`program_id`) REFERENCES `programs` (`program_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 4. ADMISSION APPLICATIONS
-- Used to test the admissions-to-enrollment pipeline.
DROP TABLE IF EXISTS `admission_applications`;
CREATE TABLE `admission_applications` (
    `applicant_id` VARCHAR(50) NOT NULL PRIMARY KEY,
    `full_name` VARCHAR(100) DEFAULT NULL,
    `status` VARCHAR(50) DEFAULT 'PENDING'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 5. STUDENTS
-- Represents officially admitted students.
DROP TABLE IF EXISTS `students`;
CREATE TABLE `students` (
    `student_number` VARCHAR(100) NOT NULL PRIMARY KEY,
    `first_name` VARCHAR(100) DEFAULT NULL,
    `last_name` VARCHAR(100) DEFAULT NULL,
    `program_code` VARCHAR(100) DEFAULT NULL,
    `year_level` INT NOT NULL DEFAULT 1,
    `semester` INT NOT NULL DEFAULT 1,
    `status` VARCHAR(50) NOT NULL DEFAULT 'ACTIVE'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 6. STUDENT LEDGER
-- Records the actual fees billed to a student based on the program_fee_settings.
DROP TABLE IF EXISTS `student_ledger`;
CREATE TABLE `student_ledger` (
    `ledger_id` INT AUTO_INCREMENT PRIMARY KEY,
    `student_id` VARCHAR(100) NOT NULL,
    `transaction_date` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `transaction_type` VARCHAR(40) DEFAULT NULL,
    `description` VARCHAR(255) DEFAULT NULL,
    `debit` DECIMAL(10,2) DEFAULT 0.00,
    `credit` DECIMAL(10,2) DEFAULT 0.00
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
