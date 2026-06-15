-- =====================================================================
-- Admission: align `applicants` with JPA Student / Applicant
--
-- Canonical copy for CAPSS deployments: registrar/db/05_admission_eacdb_align.sql
-- (section 3). When changing Student.java column set, update BOTH files together.
-- =====================================================================
-- Run on the SAME database Spring uses (e.g. `eacdb`), after picking it:
--
--     mysql -h HOST -u USER -pPASSWORD eacdb < 03_applicants_align_student_entity.sql
--
-- Uses DATABASE() — you MUST select the DB (e.g. `mysql … eacdb < this_file` or `USE eacdb;` first).
-- Safe to re-run:
--   1) Adds columns that exist on Student.java but often missing from legacy dumps.
--   2) For columns mapped as @Column(columnDefinition = "TEXT"), widens existing
--      VARCHAR / CHAR columns to TEXT (matches Student.java column definitions).
--
-- DOES NOT shorten `reference_number` to VARCHAR(32). If Hibernate complains after this,
-- investigate duplicates / length manually before ALTER-ing.
--
-- Drops `middle_namena` if present (wrong name; duplicates `middle_name_na` semantics and blocked INSERT).
-- =====================================================================

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

-- Widen VARCHAR/CHAR where entity expects unrestricted text (fewer validate mismatches).
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

-- --- Columns added by Admission flows (often absent on older dumps) -------------
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

-- Match Student.java STRING fields annotated with TEXT (camelCase → snake_case).
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

-- Accident from bad physical naming: blocks INSERT (NOT NULL, no DEFAULT). Real column is middle_name_na.
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
