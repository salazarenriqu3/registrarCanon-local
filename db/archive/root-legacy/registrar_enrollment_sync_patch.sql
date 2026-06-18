-- =============================================================================
-- eacdb_cross_system_schema.sql
-- Unified extensions for Admission + Registrar + Enrollment3 on shared eacdb.
--
-- Fresh install: merged into db/fix (run db/fix only — no other patches).
-- Legacy DB: run this file once after an older db/fix (idempotent).
--
-- Replaces:
--   registrar_enrollment_sync_patch.sql (was never shipped — now this file)
--   hotfix_complete_schema_patch.sql (students + VARCHAR migration — in db/fix)
--   05_admission_eacdb_align.sql (admission tables + programs.level)
--   enrollment3/src/main/resources/sql/enrollment_settings_schema.sql
-- =============================================================================
USE eacdb;
SET NAMES utf8mb4;
SET SQL_SAFE_UPDATES = 0;

-- ---------------------------------------------------------------------------
-- 1. sys_users / payments / courses guards (idempotent on partial runs)
-- ---------------------------------------------------------------------------
ALTER TABLE sys_users
    ADD COLUMN IF NOT EXISTS scholarship_amount   DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    ADD COLUMN IF NOT EXISTS scholarship_approved TINYINT(1)   NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS section_group        VARCHAR(10)  DEFAULT NULL;

ALTER TABLE payments
    ADD COLUMN IF NOT EXISTS bank_name    VARCHAR(100) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS check_number VARCHAR(60)  DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS check_date   DATETIME     DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS cashier_name VARCHAR(100) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS date_created DATETIME     DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE courses
    ADD COLUMN IF NOT EXISTS onlist    TINYINT(1) GENERATED ALWAYS AS (active_status) STORED,
    ADD COLUMN IF NOT EXISTS lec_units INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS lab_units INT NOT NULL DEFAULT 0;

ALTER TABLE class_schedules
    ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'OPEN';

-- ---------------------------------------------------------------------------
-- 2. Canonical students profile (Enrollment3 + Registrar)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS students (
    student_number          VARCHAR(100) NOT NULL PRIMARY KEY,
    user_id                 INT          DEFAULT NULL,
    reference_number        VARCHAR(100) DEFAULT NULL,
    first_name              VARCHAR(100) DEFAULT NULL,
    last_name               VARCHAR(100) DEFAULT NULL,
    middle_name             VARCHAR(100) DEFAULT NULL,
    real_name               VARCHAR(200) DEFAULT NULL,
    email                   VARCHAR(100) DEFAULT NULL,
    mobile                  VARCHAR(50)  DEFAULT NULL,
    street                  VARCHAR(255) DEFAULT NULL,
    city                    VARCHAR(100) DEFAULT NULL,
    province                VARCHAR(100) DEFAULT NULL,
    program_code            VARCHAR(100) DEFAULT NULL,
    year_level              INT          NOT NULL DEFAULT 1,
    semester                INT          NOT NULL DEFAULT 1,
    term_year               VARCHAR(50)  DEFAULT NULL,
    student_type            VARCHAR(50)  DEFAULT NULL,
    enrollment_status_type  VARCHAR(50)  DEFAULT NULL,
    admission_status        VARCHAR(50)  DEFAULT NULL,
    scholarship_type        VARCHAR(50)  DEFAULT NULL,
    scholarship_approved    TINYINT(1)   NOT NULL DEFAULT 0,
    scholarship_amount      DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    discount_percentage     DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    section_group           VARCHAR(10)  DEFAULT NULL,
    status                  VARCHAR(50)  NOT NULL DEFAULT 'ACTIVE',
    is_active               TINYINT(1)   NOT NULL DEFAULT 1,
    enrollment_blocked      TINYINT(1)   NOT NULL DEFAULT 0,
    enrollment_start_time   DATETIME     DEFAULT NULL,
    last_school             VARCHAR(255) DEFAULT NULL,
    course_taken            VARCHAR(255) DEFAULT NULL,
    form138_path            VARCHAR(255) DEFAULT NULL,
    good_moral_path         VARCHAR(255) DEFAULT NULL,
    psa_birth_cert_path     VARCHAR(255) DEFAULT NULL,
    id_picture_path         VARCHAR(255) DEFAULT NULL,
    password                VARCHAR(255) DEFAULT NULL,
    role                    VARCHAR(30)  NOT NULL DEFAULT 'STUDENT'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------------
-- 3. Grades — registrar period columns on canonical grades table
-- ---------------------------------------------------------------------------
ALTER TABLE grades
    ADD COLUMN IF NOT EXISTS prelim          DECIMAL(5,2) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS midterm         DECIMAL(5,2) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS final_grade     DECIMAL(5,2) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS semestral_grade DECIMAL(5,2) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS remarks         VARCHAR(30)  DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS previous_grade  VARCHAR(20)  DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS section_id      INT          DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS student_name    VARCHAR(100) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS curriculum_year INT          DEFAULT NULL;

-- ---------------------------------------------------------------------------
-- 4. programs.level (Admission portal tabs)
-- ---------------------------------------------------------------------------
SET @has_prog_level := (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'programs' AND COLUMN_NAME = 'level'
);
SET @sql_prog_level := IF(@has_prog_level = 0,
    'ALTER TABLE programs ADD COLUMN level VARCHAR(32) NULL', 'SELECT 1');
PREPARE stmt_pl FROM @sql_prog_level; EXECUTE stmt_pl; DEALLOCATE PREPARE stmt_pl;

UPDATE programs SET level = 'COLLEGE'
WHERE level IS NULL OR TRIM(level) = ''
   OR UPPER(TRIM(level)) IN ('COLLEGE', 'REGULAR');

-- ---------------------------------------------------------------------------
-- 5. Admission subsystem tables + users.email/enabled
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS school_terms (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    school_year VARCHAR(255) NOT NULL,
    semester VARCHAR(255) NOT NULL,
    code VARCHAR(255) NOT NULL,
    active TINYINT(1) NOT NULL DEFAULT 1,
    current_term TINYINT(1) NOT NULL DEFAULT 0,
    scope VARCHAR(255) NULL,
    UNIQUE KEY uk_school_terms_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS enrollment_track_settings (
    track VARCHAR(32) NOT NULL PRIMARY KEY,
    enrollment_open TINYINT(1) NOT NULL DEFAULT 1,
    closed_message TEXT NULL,
    updated_at DATETIME NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS admin_saved_filters (
    id BIGINT NOT NULL AUTO_INCREMENT,
    username VARCHAR(255) DEFAULT NULL,
    filter_name VARCHAR(255) DEFAULT NULL,
    keyword VARCHAR(255) DEFAULT NULL,
    status VARCHAR(255) DEFAULT NULL,
    track_filter VARCHAR(255) DEFAULT NULL,
    created_at DATETIME DEFAULT NULL,
    PRIMARY KEY (id),
    KEY idx_admin_saved_filters_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS requirement_upload_definitions (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    application_track VARCHAR(32) NOT NULL,
    slot_key VARCHAR(64) NOT NULL,
    display_label TEXT NOT NULL,
    kind VARCHAR(16) NOT NULL,
    active TINYINT(1) NOT NULL DEFAULT 1,
    required TINYINT(1) NOT NULL DEFAULT 1,
    sort_order INT NOT NULL,
    UNIQUE KEY uk_req_upload_track_slot (application_track, slot_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS application_logs (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    applicant_id BIGINT DEFAULT NULL,
    action VARCHAR(255) DEFAULT NULL,
    remarks TEXT,
    performed_by VARCHAR(255) DEFAULT NULL,
    actor_role VARCHAR(255) DEFAULT NULL,
    source_page VARCHAR(255) DEFAULT NULL,
    old_value TEXT,
    new_value TEXT,
    timestamp DATETIME DEFAULT NULL,
    KEY idx_application_logs_applicant (applicant_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS student_requirement_files (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    applicant_id BIGINT NOT NULL,
    definition_id BIGINT NOT NULL,
    stored_path TEXT NOT NULL,
    verified TINYINT(1) NOT NULL,
    UNIQUE KEY uk_student_req_file (applicant_id, definition_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE users
    ADD COLUMN IF NOT EXISTS email VARCHAR(255) NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS enabled TINYINT(1) NOT NULL DEFAULT 1;

UPDATE users
SET email = CONCAT(username, '@admission.local')
WHERE id IS NOT NULL AND id >= 1 AND (email IS NULL OR TRIM(email) = '');

-- ---------------------------------------------------------------------------
-- 6. Enrollment3 finance / assessment tables
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS enrollment_settings (
    setting_key   VARCHAR(80)  NOT NULL PRIMARY KEY,
    setting_value VARCHAR(500) NOT NULL,
    description   VARCHAR(255) DEFAULT NULL,
    updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS term_installment_plan (
    plan_id            INT AUTO_INCREMENT PRIMARY KEY,
    term_id            INT NULL COMMENT 'NULL = default for all terms',
    installment_number TINYINT NOT NULL,
    due_months_offset  INT NOT NULL DEFAULT 1,
    installment_label  VARCHAR(80) NOT NULL,
    UNIQUE KEY uk_term_inst (term_id, installment_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS program_general_fees (
    general_fee_id    INT AUTO_INCREMENT PRIMARY KEY,
    program_id        INT NOT NULL,
    term_id           INT NULL COMMENT 'NULL = default for all terms',
    year_level        TINYINT NOT NULL DEFAULT 1,
    semester_number   TINYINT NOT NULL DEFAULT 1,
    tuition_per_unit  DECIMAL(10,2) DEFAULT NULL,
    lec_fee_per_unit  DECIMAL(10,2) DEFAULT NULL,
    lab_fee_per_unit  DECIMAL(10,2) DEFAULT NULL,
    comp_fee_per_unit DECIMAL(10,2) DEFAULT NULL,
    rle_fee_per_unit  DECIMAL(10,2) DEFAULT NULL,
    is_active         TINYINT(1) NOT NULL DEFAULT 1,
    created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_pgf_program (program_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS program_specific_fees (
    specific_fee_id INT AUTO_INCREMENT PRIMARY KEY,
    program_id        INT NOT NULL,
    term_id           INT NULL,
    year_level        TINYINT NULL,
    semester_number   TINYINT NULL,
    fee_code          VARCHAR(30) NOT NULL,
    fee_name          VARCHAR(150) NOT NULL,
    fee_group         ENUM('MISC','OTHER','ADMISSION','PROGRAM') NOT NULL DEFAULT 'MISC',
    amount            DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    is_required       TINYINT(1) NOT NULL DEFAULT 1,
    is_active         TINYINT(1) NOT NULL DEFAULT 1,
    created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_psf_program (program_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO enrollment_settings (setting_key, setting_value, description) VALUES
('downpayment_amount', '3000', 'Fixed downpayment in PHP when percent is 0'),
('downpayment_percent', '0', 'Percent of total assessment for DP; 0 = use fixed amount'),
('max_units_regular', '24', 'Maximum credit units per term'),
('max_units_graduating_bonus', '6', 'Extra units when in final curriculum year'),
('enrollment_session_minutes', '15', 'Minutes before PENDING enlistment session blocks student'),
('drop_penalty_days_half', '7', 'Days before 50% drop penalty'),
('drop_penalty_days_full', '14', 'Days before 100% drop penalty'),
('drop_penalty_half_percent', '50', 'Penalty percent between thresholds'),
('rle_hours_per_unit', '51', 'Clinical/RLE hours per credit unit (BSN)'),
('rle_rate_per_hour', '87', 'RLE hourly rate fallback'),
('fee_fallback_enabled', 'false', 'Use DB fees only when false'),
('default_tuition_per_unit', '1483', 'Last-resort tuition per unit');

INSERT IGNORE INTO term_installment_plan (term_id, installment_number, due_months_offset, installment_label) VALUES
(NULL, 1, 1, '1st Installment'),
(NULL, 2, 2, '2nd Installment'),
(NULL, 3, 3, '3rd Installment');

-- BSIT Y1S1 fee seed (program_id 1)
INSERT IGNORE INTO program_general_fees
    (program_id, term_id, year_level, semester_number, tuition_per_unit, lec_fee_per_unit, lab_fee_per_unit, comp_fee_per_unit, is_active)
VALUES (1, NULL, 1, 1, 1483.00, 1483.00, 0.00, 200.00, 1);

INSERT IGNORE INTO program_specific_fees
    (program_id, term_id, year_level, semester_number, fee_code, fee_name, fee_group, amount, is_required, is_active)
VALUES
(1, NULL, 1, 1, 'MISC_REG', 'Registration', 'MISC', 876.00, 1, 1),
(1, NULL, 1, 1, 'MISC_GUIDANCE', 'Guidance & Counselling', 'MISC', 439.00, 1, 1),
(1, NULL, 1, 1, 'MISC_LMS', 'Learning Management System', 'MISC', 514.00, 1, 1),
(1, NULL, 1, 1, 'MISC_MED', 'Medical / Dental', 'MISC', 1006.00, 1, 1),
(1, NULL, 1, 1, 'MISC_ATHLETIC', 'Athletic Fee', 'MISC', 627.00, 1, 1),
(1, NULL, 1, 1, 'MISC_LIBRARY', 'Library Fee', 'MISC', 1389.00, 1, 1),
(1, NULL, 1, 1, 'OTHER_ID', 'Identification Card', 'OTHER', 150.00, 1, 1),
(1, NULL, 1, 1, 'OTHER_INS', 'Insurance', 'OTHER', 400.00, 1, 1);

-- ---------------------------------------------------------------------------
-- 7. Registrar VPAA + grade change workflow
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS vpaa_extensions (
    ext_id      INT AUTO_INCREMENT PRIMARY KEY,
    schedule_id INT,
    faculty_id  INT,
    status      VARCHAR(50) DEFAULT 'PENDING',
    reason      VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS grade_change_requests (
    request_id      INT AUTO_INCREMENT PRIMARY KEY,
    grade_id        BIGINT,
    student_name    VARCHAR(100),
    course_code     VARCHAR(20),
    faculty_name    VARCHAR(100),
    requested_grade VARCHAR(20),
    reason          TEXT,
    status          VARCHAR(30) DEFAULT 'PENDING',
    request_date    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP VIEW IF EXISTS student_grades;
CREATE OR REPLACE VIEW student_grades AS
SELECT
    g.id              AS grade_id,
    g.section_id      AS schedule_id,
    g.student_name,
    g.student_id,
    g.prelim,
    g.midterm,
    g.final_grade     AS `final`,
    g.semestral_grade,
    g.remarks,
    g.previous_grade,
    COALESCE(g.status, 'DRAFT') AS status
FROM grades g;

-- ---------------------------------------------------------------------------
-- 8. Grading period settings (registrar AcademicGradingService)
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO system_settings (setting_key, setting_value) VALUES
('PRELIM_START', '2025-08-01'),
('PRELIM_END', '2025-09-15'),
('MIDTERM_START', '2025-10-01'),
('MIDTERM_END', '2025-11-15'),
('FINAL_START', '2025-12-01'),
('FINAL_END', '2025-12-20'),
('PRELIM_OVERRIDE', ''),
('MIDTERM_OVERRIDE', ''),
('FINAL_OVERRIDE', ''),
('enrollment_open', 'true');

UPDATE system_settings SET setting_value = 'true' WHERE setting_key = 'enrollment_open';

-- ---------------------------------------------------------------------------
-- 9. Staff logins (Enrollment3 + Registrar) — password: 1234
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO sys_users (username, password, real_name, role, is_active, status) VALUES
('admin',   '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EhsLkT/Oh.reShMkwpfpJ2', 'System Administrator', 'Admin',   1, 'ACTIVE'),
('cashier', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EhsLkT/Oh.reShMkwpfpJ2', 'Enrollment Cashier',   'Cashier', 1, 'ACTIVE'),
('faculty', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EhsLkT/Oh.reShMkwpfpJ2', 'Faculty Demo',         'Faculty', 1, 'ACTIVE'),
('prof',    '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EhsLkT/Oh.reShMkwpfpJ2', 'Professor Demo',       'Faculty', 1, 'ACTIVE');

-- ---------------------------------------------------------------------------
-- 10. Verification
-- ---------------------------------------------------------------------------
SELECT 'eacdb_cross_system_schema applied' AS status;

SELECT TABLE_NAME, COLUMN_NAME
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'grades'
  AND COLUMN_NAME IN ('prelim','midterm','final_grade','semestral_grade');

SELECT TABLE_NAME, TABLE_TYPE
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME IN ('student_grades','enrollment_settings','program_general_fees','school_terms');

SET SQL_SAFE_UPDATES = 1;
