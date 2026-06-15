-- =====================================================================
-- CAPSS — Admission subsystem alignment for shared `eacdb`
--
-- DEPRECATED (May 27 2026): Merged into db/fix and db/eacdb_cross_system_schema.sql.
-- Fresh install: run db/fix only.
-- Legacy DB: run db/eacdb_cross_system_schema.sql instead of this file.
--
-- Run in MySQL Workbench AFTER:
--   db/fix
--   registrar_enrollment_sync_patch.sql   (or hotfix_complete_schema_patch.sql)
--
-- BEFORE deploying admission.war on Tomcat. Safe to re-run (idempotent).
--
-- Canonical duplicate of applicants column widen/add logic also ships under:
--   AdmissionEAC/admission/src/main/resources/db/03_applicants_align_student_entity.sql
-- Keep those two in sync when Student.java changes.
-- =====================================================================

SET NAMES utf8mb4;

-- ---------------------------------------------------------------------------
-- 1) Admission-owned tables (not created by 01_schema_eacdb_unified.sql)
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
    KEY idx_application_logs_applicant (applicant_id),
    CONSTRAINT fk_application_logs_applicant FOREIGN KEY (applicant_id)
        REFERENCES applicants(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS student_requirement_files (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    applicant_id BIGINT NOT NULL,
    definition_id BIGINT NOT NULL,
    stored_path TEXT NOT NULL,
    verified TINYINT(1) NOT NULL,
    UNIQUE KEY uk_student_req_file (applicant_id, definition_id),
    CONSTRAINT fk_student_req_applicant FOREIGN KEY (applicant_id)
        REFERENCES applicants(id) ON DELETE CASCADE,
    CONSTRAINT fk_student_req_definition FOREIGN KEY (definition_id)
        REFERENCES requirement_upload_definitions(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------------
-- 2) Shared `programs` / `users` adjustments (Admission User.java + Program tabs)
-- ---------------------------------------------------------------------------

SET @has_level := (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'programs' AND COLUMN_NAME = 'level'
);
SET @sql_level := IF(@has_level = 0, 'ALTER TABLE programs ADD COLUMN level VARCHAR(32) NULL', 'SELECT 1');
PREPARE stmt_level FROM @sql_level;
EXECUTE stmt_level;
DEALLOCATE PREPARE stmt_level;

SET @has_email := (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'email'
);
SET @sql_email := IF(@has_email = 0,
    'ALTER TABLE users ADD COLUMN email VARCHAR(255) NOT NULL DEFAULT ''''',
    'SELECT 1');
PREPARE stmt_email FROM @sql_email;
EXECUTE stmt_email;
DEALLOCATE PREPARE stmt_email;

SET @has_enabled := (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'enabled'
);
SET @sql_enabled := IF(@has_enabled = 0,
    'ALTER TABLE users ADD COLUMN enabled TINYINT(1) NOT NULL DEFAULT 1',
    'SELECT 1');
PREPARE stmt_enabled FROM @sql_enabled;
EXECUTE stmt_enabled;
DEALLOCATE PREPARE stmt_enabled;

UPDATE users
SET email = CONCAT(username, '@admission.local')
WHERE id IS NOT NULL
  AND id >= 1
  AND (email IS NULL OR TRIM(email) = '');

UPDATE programs SET level = 'COLLEGE'
WHERE program_id IS NOT NULL
  AND program_id >= 1
  AND (level IS NULL OR TRIM(level) = '' OR UPPER(TRIM(level)) IN ('COLLEGE', 'REGULAR'));

UPDATE programs SET level = 'SHS'
WHERE program_id IS NOT NULL
  AND program_id >= 1
  AND UPPER(TRIM(level)) IN ('SHS', 'SHS_TRACK', 'SENIOR HIGH SCHOOL');

UPDATE programs SET level = 'MASTERAL'
WHERE program_id IS NOT NULL
  AND program_id >= 1
  AND UPPER(TRIM(level)) IN ('MASTERAL', 'GRADUATE');

-- ---------------------------------------------------------------------------
-- 3) Align `applicants` with Admission JPA Student / Applicant (add + widen TEXT)
-- ---------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS admission_add_applicants_column_if_missing;
DROP PROCEDURE IF EXISTS admission_widen_applicants_text_column_if_needed;

DELIMITER $$

CREATE PROCEDURE admission_add_applicants_column_if_missing(
    IN p_col VARCHAR(64),
    IN p_ddl VARCHAR(512)
)
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'applicants'
          AND COLUMN_NAME = p_col
    ) THEN
        SET @ddl_stmt = CONCAT('ALTER TABLE `applicants` ADD COLUMN `', p_col, '` ', p_ddl);
        PREPARE stmt_adm_add FROM @ddl_stmt;
        EXECUTE stmt_adm_add;
        DEALLOCATE PREPARE stmt_adm_add;
    END IF;
END$$

CREATE PROCEDURE admission_widen_applicants_text_column_if_needed(IN p_col VARCHAR(64))
BEGIN
    DECLARE v_type VARCHAR(64);
    SELECT DATA_TYPE INTO v_type
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'applicants'
      AND COLUMN_NAME = p_col;
    IF v_type IS NOT NULL AND v_type IN ('varchar', 'char') THEN
        SET @ddl_wide = CONCAT(
            'ALTER TABLE `applicants` MODIFY COLUMN `', p_col,
            '` TEXT NULL');
        PREPARE stmt_wide FROM @ddl_wide;
        EXECUTE stmt_wide;
        DEALLOCATE PREPARE stmt_wide;
    END IF;
END$$

DELIMITER ;

CALL admission_add_applicants_column_if_missing('application_track', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('degree_certificate_program', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('enrollment_term', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('school_year_text', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('admission_classification', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('lrn', 'TEXT NULL');

CALL admission_add_applicants_column_if_missing('visa_status', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('period_of_authorized_stay', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('passport_no', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('passport_issue_date', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('passport_expiry_date', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('acr_no', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('acr_issue_date', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('acr_expiry_date', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('crt_no', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('crt_issue_date', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('crt_expiry_date', 'TEXT NULL');

CALL admission_add_applicants_column_if_missing('father_company_address', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('mother_company_address', 'TEXT NULL');

CALL admission_add_applicants_column_if_missing('guardian_age', 'INT NULL');
CALL admission_add_applicants_column_if_missing('guardian_occupation', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('guardian_home_address', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('guardian_landline', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('guardian_mobile', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('guardian_email', 'TEXT NULL');

CALL admission_add_applicants_column_if_missing('undergrad_school_address', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('grad_program_school', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('grad_program_address', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('grad_program_year', 'TEXT NULL');

CALL admission_add_applicants_column_if_missing('privacy_consent_accepted', 'TINYINT(1) NOT NULL DEFAULT 0');
CALL admission_add_applicants_column_if_missing('privacy_consent_by_guardian', 'TINYINT(1) NOT NULL DEFAULT 0');
CALL admission_add_applicants_column_if_missing('declaration_learner_name', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('declaration_accomplished_date', 'TEXT NULL');

CALL admission_add_applicants_column_if_missing('foreign_city_address', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('foreign_city_tel', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('foreign_provincial_address', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('foreign_provincial_tel', 'TEXT NULL');

CALL admission_add_applicants_column_if_missing('foreign_home_house_name', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('foreign_home_street', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('foreign_home_province', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('foreign_home_city', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('foreign_home_country', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('foreign_home_zip', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('foreign_home_tel', 'TEXT NULL');

CALL admission_add_applicants_column_if_missing('foreign_current_house_name', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('foreign_current_street', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('foreign_current_province', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('foreign_current_city', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('foreign_current_country', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('foreign_current_zip', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('foreign_current_tel', 'TEXT NULL');

CALL admission_add_applicants_column_if_missing('foreign_emergency_house_name', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('foreign_emergency_street', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('foreign_emergency_province', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('foreign_emergency_city', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('foreign_emergency_country', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('foreign_emergency_zip', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('foreign_emergency_tel', 'TEXT NULL');

CALL admission_add_applicants_column_if_missing('father_age', 'INT NULL');
CALL admission_add_applicants_column_if_missing('mother_age', 'INT NULL');
CALL admission_add_applicants_column_if_missing('father_landline', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('father_email', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('father_office_tel', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('father_highest_education', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('father_schools_attended', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('mother_landline', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('mother_email', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('mother_office_tel', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('mother_highest_education', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('mother_schools_attended', 'TEXT NULL');

CALL admission_add_applicants_column_if_missing('foreign_siblings_json', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('foreign_references_json', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('foreign_edu_elementary', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('foreign_edu_high_school', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('foreign_edu_college', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('foreign_edu_post_graduate', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('foreign_edu_vocational', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('foreign_certification_accepted', 'TINYINT(1) NOT NULL DEFAULT 0');

CALL admission_add_applicants_column_if_missing('email_verification_token', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('interview_mode', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('interview_venue', 'TEXT NULL');
CALL admission_add_applicants_column_if_missing('reopen_reminder_sent_at', 'DATETIME NULL');

CALL admission_widen_applicants_text_column_if_needed('academic_level');
CALL admission_widen_applicants_text_column_if_needed('admission_classification');
CALL admission_widen_applicants_text_column_if_needed('applicant_status');
CALL admission_widen_applicants_text_column_if_needed('application_track');
CALL admission_widen_applicants_text_column_if_needed('course_taken');
CALL admission_widen_applicants_text_column_if_needed('citizenship');
CALL admission_widen_applicants_text_column_if_needed('civil_status');
CALL admission_widen_applicants_text_column_if_needed('city');
CALL admission_widen_applicants_text_column_if_needed('crt_expiry_date');
CALL admission_widen_applicants_text_column_if_needed('crt_issue_date');
CALL admission_widen_applicants_text_column_if_needed('crt_no');
CALL admission_widen_applicants_text_column_if_needed('declaration_accomplished_date');
CALL admission_widen_applicants_text_column_if_needed('declaration_learner_name');
CALL admission_widen_applicants_text_column_if_needed('degree_certificate_program');
CALL admission_widen_applicants_text_column_if_needed('dob');
CALL admission_widen_applicants_text_column_if_needed('email');
CALL admission_widen_applicants_text_column_if_needed('email_verification_token');
CALL admission_widen_applicants_text_column_if_needed('elementary_address');
CALL admission_widen_applicants_text_column_if_needed('elementary_school');
CALL admission_widen_applicants_text_column_if_needed('elementary_year');
CALL admission_widen_applicants_text_column_if_needed('emergency_contact_mobile');
CALL admission_widen_applicants_text_column_if_needed('emergency_contact_name');
CALL admission_widen_applicants_text_column_if_needed('emergency_contact_relationship');
CALL admission_widen_applicants_text_column_if_needed('enrollment_term');
CALL admission_widen_applicants_text_column_if_needed('extension');
CALL admission_widen_applicants_text_column_if_needed('father_address');
CALL admission_widen_applicants_text_column_if_needed('father_company_address');
CALL admission_widen_applicants_text_column_if_needed('father_contact');
CALL admission_widen_applicants_text_column_if_needed('father_email');
CALL admission_widen_applicants_text_column_if_needed('father_highest_education');
CALL admission_widen_applicants_text_column_if_needed('father_landline');
CALL admission_widen_applicants_text_column_if_needed('father_name');
CALL admission_widen_applicants_text_column_if_needed('father_occupation');
CALL admission_widen_applicants_text_column_if_needed('father_office_tel');
CALL admission_widen_applicants_text_column_if_needed('father_schools_attended');
CALL admission_widen_applicants_text_column_if_needed('first_name');
CALL admission_widen_applicants_text_column_if_needed('foreign_city_address');
CALL admission_widen_applicants_text_column_if_needed('foreign_city_tel');
CALL admission_widen_applicants_text_column_if_needed('foreign_current_city');
CALL admission_widen_applicants_text_column_if_needed('foreign_current_country');
CALL admission_widen_applicants_text_column_if_needed('foreign_current_house_name');
CALL admission_widen_applicants_text_column_if_needed('foreign_current_province');
CALL admission_widen_applicants_text_column_if_needed('foreign_current_street');
CALL admission_widen_applicants_text_column_if_needed('foreign_current_tel');
CALL admission_widen_applicants_text_column_if_needed('foreign_current_zip');
CALL admission_widen_applicants_text_column_if_needed('foreign_edu_college');
CALL admission_widen_applicants_text_column_if_needed('foreign_edu_elementary');
CALL admission_widen_applicants_text_column_if_needed('foreign_edu_high_school');
CALL admission_widen_applicants_text_column_if_needed('foreign_edu_post_graduate');
CALL admission_widen_applicants_text_column_if_needed('foreign_edu_vocational');
CALL admission_widen_applicants_text_column_if_needed('foreign_emergency_city');
CALL admission_widen_applicants_text_column_if_needed('foreign_emergency_country');
CALL admission_widen_applicants_text_column_if_needed('foreign_emergency_house_name');
CALL admission_widen_applicants_text_column_if_needed('foreign_emergency_province');
CALL admission_widen_applicants_text_column_if_needed('foreign_emergency_street');
CALL admission_widen_applicants_text_column_if_needed('foreign_emergency_tel');
CALL admission_widen_applicants_text_column_if_needed('foreign_emergency_zip');
CALL admission_widen_applicants_text_column_if_needed('foreign_home_city');
CALL admission_widen_applicants_text_column_if_needed('foreign_home_country');
CALL admission_widen_applicants_text_column_if_needed('foreign_home_house_name');
CALL admission_widen_applicants_text_column_if_needed('foreign_home_province');
CALL admission_widen_applicants_text_column_if_needed('foreign_home_street');
CALL admission_widen_applicants_text_column_if_needed('foreign_home_tel');
CALL admission_widen_applicants_text_column_if_needed('foreign_home_zip');
CALL admission_widen_applicants_text_column_if_needed('foreign_provincial_address');
CALL admission_widen_applicants_text_column_if_needed('foreign_provincial_tel');
CALL admission_widen_applicants_text_column_if_needed('foreign_references_json');
CALL admission_widen_applicants_text_column_if_needed('foreign_siblings_json');
CALL admission_widen_applicants_text_column_if_needed('form138_path');
CALL admission_widen_applicants_text_column_if_needed('good_moral_path');
CALL admission_widen_applicants_text_column_if_needed('grad_program_address');
CALL admission_widen_applicants_text_column_if_needed('grad_program_school');
CALL admission_widen_applicants_text_column_if_needed('grad_program_year');
CALL admission_widen_applicants_text_column_if_needed('guardian_contact');
CALL admission_widen_applicants_text_column_if_needed('guardian_email');
CALL admission_widen_applicants_text_column_if_needed('guardian_home_address');
CALL admission_widen_applicants_text_column_if_needed('guardian_landline');
CALL admission_widen_applicants_text_column_if_needed('guardian_mobile');
CALL admission_widen_applicants_text_column_if_needed('guardian_name');
CALL admission_widen_applicants_text_column_if_needed('guardian_occupation');
CALL admission_widen_applicants_text_column_if_needed('guardian_relationship');
CALL admission_widen_applicants_text_column_if_needed('id_picture_path');
CALL admission_widen_applicants_text_column_if_needed('interview_date');
CALL admission_widen_applicants_text_column_if_needed('interview_link');
CALL admission_widen_applicants_text_column_if_needed('interview_mode');
CALL admission_widen_applicants_text_column_if_needed('interview_time');
CALL admission_widen_applicants_text_column_if_needed('interview_venue');
CALL admission_widen_applicants_text_column_if_needed('jhs_address');
CALL admission_widen_applicants_text_column_if_needed('jhs_school');
CALL admission_widen_applicants_text_column_if_needed('jhs_year');
CALL admission_widen_applicants_text_column_if_needed('last_name');
CALL admission_widen_applicants_text_column_if_needed('last_school');
CALL admission_widen_applicants_text_column_if_needed('last_school_year');
CALL admission_widen_applicants_text_column_if_needed('landline');
CALL admission_widen_applicants_text_column_if_needed('lrn');
CALL admission_widen_applicants_text_column_if_needed('marriage_cert_path');
CALL admission_widen_applicants_text_column_if_needed('middle_initial');
CALL admission_widen_applicants_text_column_if_needed('middle_name');
CALL admission_widen_applicants_text_column_if_needed('mobile');
CALL admission_widen_applicants_text_column_if_needed('mother_address');
CALL admission_widen_applicants_text_column_if_needed('mother_company_address');
CALL admission_widen_applicants_text_column_if_needed('mother_contact');
CALL admission_widen_applicants_text_column_if_needed('mother_email');
CALL admission_widen_applicants_text_column_if_needed('mother_highest_education');
CALL admission_widen_applicants_text_column_if_needed('mother_landline');
CALL admission_widen_applicants_text_column_if_needed('mother_name');
CALL admission_widen_applicants_text_column_if_needed('mother_occupation');
CALL admission_widen_applicants_text_column_if_needed('mother_office_tel');
CALL admission_widen_applicants_text_column_if_needed('mother_schools_attended');
CALL admission_widen_applicants_text_column_if_needed('monthly_income');
CALL admission_widen_applicants_text_column_if_needed('nationality');
CALL admission_widen_applicants_text_column_if_needed('other_doc_path');
CALL admission_widen_applicants_text_column_if_needed('passport_expiry_date');
CALL admission_widen_applicants_text_column_if_needed('passport_issue_date');
CALL admission_widen_applicants_text_column_if_needed('passport_no');
CALL admission_widen_applicants_text_column_if_needed('period_of_authorized_stay');
CALL admission_widen_applicants_text_column_if_needed('place_of_birth');
CALL admission_widen_applicants_text_column_if_needed('program1');
CALL admission_widen_applicants_text_column_if_needed('program2');
CALL admission_widen_applicants_text_column_if_needed('psa_birth_cert_path');
CALL admission_widen_applicants_text_column_if_needed('province');
CALL admission_widen_applicants_text_column_if_needed('religion');
CALL admission_widen_applicants_text_column_if_needed('school_year_text');
CALL admission_widen_applicants_text_column_if_needed('sex');
CALL admission_widen_applicants_text_column_if_needed('shs_address');
CALL admission_widen_applicants_text_column_if_needed('shs_school');
CALL admission_widen_applicants_text_column_if_needed('shs_track');
CALL admission_widen_applicants_text_column_if_needed('shs_year');
CALL admission_widen_applicants_text_column_if_needed('sibling_order');
CALL admission_widen_applicants_text_column_if_needed('street');
CALL admission_widen_applicants_text_column_if_needed('term_year');
CALL admission_widen_applicants_text_column_if_needed('undergrad_school_address');
CALL admission_widen_applicants_text_column_if_needed('visa_status');
CALL admission_widen_applicants_text_column_if_needed('zip');

SET @has_middle_typo := (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'applicants'
      AND COLUMN_NAME = 'middle_namena'
);
SET @sql_drop_typo := IF(@has_middle_typo > 0, 'ALTER TABLE applicants DROP COLUMN middle_namena', 'SELECT 1');
PREPARE stmt_drop_typo FROM @sql_drop_typo;
EXECUTE stmt_drop_typo;
DEALLOCATE PREPARE stmt_drop_typo;

DROP PROCEDURE IF EXISTS admission_add_applicants_column_if_missing;
DROP PROCEDURE IF EXISTS admission_widen_applicants_text_column_if_needed;
