-- =============================================================================
-- Sprint 1–10 schema upgrade (idempotent)
-- Safe to re-run on existing eacdb instances (staging / prod promote).
--
-- Apply:
--   mysql -u root -p eacdb < registrar/db/migrations/20260619_sprint_1_10_upgrade.sql
-- Or:
--   registrar\db\migrations\RUN_UPGRADE.cmd
-- =============================================================================

USE eacdb;

-- ── Helper: add column if missing ───────────────────────────────────────────
DROP PROCEDURE IF EXISTS sp_add_column_if_missing;
DELIMITER //
CREATE PROCEDURE sp_add_column_if_missing(
    IN p_table VARCHAR(64),
    IN p_column VARCHAR(64),
    IN p_definition TEXT
)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = DATABASE()
          AND table_name = p_table
          AND column_name = p_column
    ) THEN
        SET @ddl = CONCAT('ALTER TABLE `', p_table, '` ADD COLUMN `', p_column, '` ', p_definition);
        PREPARE stmt FROM @ddl;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END//
DELIMITER ;

-- ── programs.duration_years (Sprint 1) ──────────────────────────────────────
CALL sp_add_column_if_missing('programs', 'duration_years', 'INT NOT NULL DEFAULT 4');

-- ── courses.course_type (Sprint 9) ──────────────────────────────────────────
CALL sp_add_column_if_missing('courses', 'course_type', "VARCHAR(20) NOT NULL DEFAULT 'REGULAR'");
CALL sp_add_column_if_missing('courses', 'lec_units', 'INT NOT NULL DEFAULT 0');
CALL sp_add_column_if_missing('courses', 'lab_units', 'INT NOT NULL DEFAULT 0');

-- ── class_sections.petition_min_headcount (Sprint 9) ────────────────────────
CALL sp_add_column_if_missing('class_sections', 'petition_min_headcount', 'INT NULL');

-- ── academic_term_policies.midterm_exam_date (Sprint 4) ─────────────────────
CREATE TABLE IF NOT EXISTS academic_term_policies (
    term_id INT PRIMARY KEY,
    inc_expiration_date DATE NULL,
    midterm_exam_date DATE NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CALL sp_add_column_if_missing('academic_term_policies', 'midterm_exam_date', 'DATE NULL');

-- ── grading_schemes (Sprint 5) ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS grading_schemes (
    scheme_id INT AUTO_INCREMENT PRIMARY KEY,
    program_code VARCHAR(20) NULL,
    class_standing_percent DECIMAL(5,2) NOT NULL DEFAULT 50.00,
    exam_percent DECIMAL(5,2) NOT NULL DEFAULT 50.00,
    base_scale VARCHAR(20) NOT NULL DEFAULT 'POINT',
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_grading_scheme_program (program_code)
);
INSERT INTO grading_schemes (program_code, class_standing_percent, exam_percent, base_scale)
SELECT NULL, 50.00, 50.00, 'POINT'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM grading_schemes WHERE program_code IS NULL);

-- ── student_holds (Sprint 6) ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS student_holds (
    hold_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    student_number VARCHAR(100) NOT NULL,
    office VARCHAR(30) NOT NULL,
    reason VARCHAR(500) NOT NULL,
    active TINYINT(1) NOT NULL DEFAULT 1,
    created_by VARCHAR(100) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    cleared_by VARCHAR(100) NULL,
    cleared_at TIMESTAMP NULL,
    KEY idx_sh_student_active (student_number, active)
);

-- ── student_program_shift_requests (Sprint 4) ───────────────────────────────
CREATE TABLE IF NOT EXISTS student_program_shift_requests (
    request_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    student_number VARCHAR(100) NOT NULL,
    from_program_code VARCHAR(20) NULL,
    to_program_code VARCHAR(20) NOT NULL,
    target_year_level INT NULL,
    target_semester INT NULL,
    target_curriculum_id INT NULL,
    reason VARCHAR(500) NULL,
    status VARCHAR(40) NOT NULL DEFAULT 'PENDING_DEAN',
    requested_by VARCHAR(100) NULL,
    requested_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dean_approved_by VARCHAR(100) NULL,
    dean_approved_at TIMESTAMP NULL,
    registrar_approved_by VARCHAR(100) NULL,
    registrar_approved_at TIMESTAMP NULL,
    rejected_by VARCHAR(100) NULL,
    rejected_at TIMESTAMP NULL,
    rejection_reason VARCHAR(500) NULL,
    completed_at TIMESTAMP NULL,
    KEY idx_spsr_status (status),
    KEY idx_spsr_student (student_number)
);

-- ── enrollment period system_settings (Sprint 8) ─────────────────────────────
INSERT INTO system_settings (setting_key, setting_value)
SELECT 'ENROLLMENT_OPEN_DATE', ''
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM system_settings WHERE setting_key = 'ENROLLMENT_OPEN_DATE');

INSERT INTO system_settings (setting_key, setting_value)
SELECT 'ENROLLMENT_CLOSE_DATE', ''
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM system_settings WHERE setting_key = 'ENROLLMENT_CLOSE_DATE');

INSERT INTO system_settings (setting_key, setting_value)
SELECT 'ADD_DROP_CLOSE_DATE', ''
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM system_settings WHERE setting_key = 'ADD_DROP_CLOSE_DATE');

INSERT INTO system_settings (setting_key, setting_value)
SELECT 'LATE_ENROLLMENT_FEE_ENABLED', 'false'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM system_settings WHERE setting_key = 'LATE_ENROLLMENT_FEE_ENABLED');

-- ── withdrawal penalty setting (Sprint 4) ───────────────────────────────────
CREATE TABLE IF NOT EXISTS enrollment_settings (
    setting_key VARCHAR(80) PRIMARY KEY,
    setting_value VARCHAR(255) NOT NULL,
    description VARCHAR(255) NULL
);
INSERT INTO enrollment_settings (setting_key, setting_value, description)
SELECT 'drop_penalty_first_week_percent', '25', 'First-two-weeks withdrawal charge percent'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM enrollment_settings WHERE setting_key = 'drop_penalty_first_week_percent');

-- ── withdrawal tables (ensure exist — prior sprints) ────────────────────────
CREATE TABLE IF NOT EXISTS withdrawal_reasons (
    reason_code VARCHAR(40) PRIMARY KEY,
    reason_label VARCHAR(160) NOT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    sort_order INT NOT NULL DEFAULT 100
);

INSERT INTO withdrawal_reasons (reason_code, reason_label, sort_order) VALUES
('SCHEDULE_CONFLICT', 'Schedule conflict', 10),
('HEALTH', 'Health / medical', 20),
('FINANCIAL', 'Financial hardship', 30),
('ACADEMIC', 'Academic difficulty', 40),
('TRANSFER', 'Transfer to another school', 50),
('OTHER', 'Other (see remarks)', 99)
ON DUPLICATE KEY UPDATE reason_label = VALUES(reason_label);

CREATE TABLE IF NOT EXISTS student_withdrawal_requests (
    request_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    student_number VARCHAR(100) NOT NULL,
    section_id INT NOT NULL,
    course_id INT NOT NULL,
    term_id INT NULL,
    reason_code VARCHAR(40) NOT NULL,
    remarks VARCHAR(500) NULL,
    requested_on DATE NULL,
    enlisted_at TIMESTAMP NULL,
    days_enrolled_at_request INT NULL,
    timing_bucket VARCHAR(40) NULL,
    charge_percent DECIMAL(5,2) NOT NULL DEFAULT 0,
    estimated_charge DECIMAL(12,2) NOT NULL DEFAULT 0,
    deadline_blocked TINYINT(1) NOT NULL DEFAULT 0,
    policy_note VARCHAR(255) NULL,
    status VARCHAR(40) NOT NULL DEFAULT 'PENDING_DEAN',
    requested_by VARCHAR(100) NULL,
    requested_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dean_approved_by VARCHAR(100) NULL,
    dean_approved_at TIMESTAMP NULL,
    registrar_approved_by VARCHAR(100) NULL,
    registrar_approved_at TIMESTAMP NULL,
    rejected_by VARCHAR(100) NULL,
    rejected_at TIMESTAMP NULL,
    rejection_reason VARCHAR(500) NULL,
    completed_at TIMESTAMP NULL
);

DROP PROCEDURE IF EXISTS sp_add_column_if_missing;

SELECT 'SPRINT_1_10_UPGRADE' AS status, 'OK' AS result, NOW() AS applied_at;
