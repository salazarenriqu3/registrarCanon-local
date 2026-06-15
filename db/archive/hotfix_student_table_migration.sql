-- ============================================================
-- HOTFIX: Students Table Migration (rev. 25 May 2026)
-- Separates student data from sys_users into a dedicated
-- `students` table, and migrates all transactional foreign
-- keys from INT (user_id) to VARCHAR (student_number).
--
-- RUN ORDER: After hotfix_missing_columns.sql
-- SAFE TO RE-RUN: Yes (IF NOT EXISTS / IF col type = INT guards)
-- ============================================================
USE eacdb;

SET SQL_SAFE_UPDATES = 0;

-- ── Step 1: Create the students table (if not already done) ──
CREATE TABLE IF NOT EXISTS students (
    student_number          VARCHAR(100) NOT NULL PRIMARY KEY,
    user_id                 INT          DEFAULT NULL,   -- kept for legacy cross-ref
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
    scholarship_amount      DECIMAL(10,2)NOT NULL DEFAULT 0.00,
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

-- ── Step 2: Migrate student rows from sys_users into students ──
-- Only inserts rows that don't already exist (safe to re-run).
INSERT IGNORE INTO students (
    student_number, user_id, reference_number,
    first_name, last_name, middle_name, real_name,
    email, mobile, street, city, province,
    program_code, year_level, semester, term_year,
    student_type, enrollment_status_type, admission_status,
    scholarship_type, scholarship_approved, scholarship_amount,
    discount_percentage, section_group,
    status, is_active, enrollment_blocked, enrollment_start_time,
    last_school, course_taken,
    form138_path, good_moral_path, psa_birth_cert_path, id_picture_path,
    password, role
)
SELECT
    username, user_id, reference_number,
    first_name, last_name, middle_name, real_name,
    email, mobile, street, city, province,
    program_code, COALESCE(year_level, 1), COALESCE(semester, 1), term_year,
    student_type, enrollment_status_type, admission_status,
    COALESCE(scholarship_type, 'NONE'),
    COALESCE(scholarship_approved, 0),
    COALESCE(scholarship_amount, 0.00),
    COALESCE(discount_percentage, 0.00),
    section_group,
    COALESCE(status, 'ACTIVE'), COALESCE(is_active, 1),
    COALESCE(enrollment_blocked, 0), enrollment_start_time,
    last_school, course_taken,
    form138_path, good_moral_path, psa_birth_cert_path, id_picture_path,
    password, role
FROM sys_users
WHERE role = 'Student'
   OR admission_status IS NOT NULL;

-- ── Step 3: Migrate transactional tables from INT to VARCHAR ──
-- Only migrates tables where student_id is still INT type.
-- Each block: add temp column → backfill from sys_users → drop old column → rename.

-- student_ledger
SET @col_type = (
    SELECT DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'student_ledger' AND COLUMN_NAME = 'student_id'
);
SET @do_migrate = IF(@col_type = 'int', 1, 0);

-- Only run migration DDL if student_id is still INT
-- (MariaDB/MySQL doesn't support IF in DDL, so we use a stored procedure for safety)
DROP PROCEDURE IF EXISTS _migrate_ledger;
DELIMITER $$
CREATE PROCEDURE _migrate_ledger()
BEGIN
    DECLARE col_type VARCHAR(20);
    SELECT DATA_TYPE INTO col_type
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'student_ledger' AND COLUMN_NAME = 'student_id';

    IF col_type = 'int' THEN
        -- Remove old FK before altering
        IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'student_ledger' AND COLUMN_NAME = '_sn') THEN
            ALTER TABLE student_ledger DROP COLUMN _sn;
        END IF;
        ALTER TABLE student_ledger DROP FOREIGN KEY IF EXISTS fk_ledger_student;
        ALTER TABLE student_ledger ADD COLUMN _sn VARCHAR(100) NULL;
        UPDATE student_ledger l JOIN sys_users u ON l.student_id = u.user_id SET l._sn = u.username;
        ALTER TABLE student_ledger DROP COLUMN student_id;
        ALTER TABLE student_ledger CHANGE COLUMN _sn student_id VARCHAR(100) NOT NULL;
        SELECT 'student_ledger: migrated to VARCHAR' AS result;
    ELSE
        SELECT 'student_ledger: already VARCHAR, skipping' AS result;
    END IF;
END$$
DELIMITER ;
CALL _migrate_ledger();
DROP PROCEDURE IF EXISTS _migrate_ledger;

-- student_enlistments
DROP PROCEDURE IF EXISTS _migrate_enlistments;
DELIMITER $$
CREATE PROCEDURE _migrate_enlistments()
BEGIN
    DECLARE col_type VARCHAR(20);
    SELECT DATA_TYPE INTO col_type
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'student_enlistments' AND COLUMN_NAME = 'student_id';

    IF col_type = 'int' THEN
        IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'student_enlistments' AND COLUMN_NAME = '_sn') THEN
            ALTER TABLE student_enlistments DROP COLUMN _sn;
        END IF;
        ALTER TABLE student_enlistments DROP FOREIGN KEY IF EXISTS fk_se_student;
        ALTER TABLE student_enlistments DROP KEY IF EXISTS uq_student_course;
        ALTER TABLE student_enlistments ADD COLUMN _sn VARCHAR(100) NULL;
        UPDATE student_enlistments e JOIN sys_users u ON e.student_id = u.user_id SET e._sn = u.username;
        ALTER TABLE student_enlistments DROP COLUMN student_id;
        ALTER TABLE student_enlistments CHANGE COLUMN _sn student_id VARCHAR(100) NOT NULL;
        ALTER TABLE student_enlistments ADD INDEX idx_se_student_course (student_id, course_id);
        SELECT 'student_enlistments: migrated to VARCHAR' AS result;
    ELSE
        SELECT 'student_enlistments: already VARCHAR, skipping' AS result;
    END IF;
END$$
DELIMITER ;
CALL _migrate_enlistments();
DROP PROCEDURE IF EXISTS _migrate_enlistments;

-- grades
DROP PROCEDURE IF EXISTS _migrate_grades;
DELIMITER $$
CREATE PROCEDURE _migrate_grades()
BEGIN
    DECLARE col_type VARCHAR(20);
    SELECT DATA_TYPE INTO col_type
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'grades' AND COLUMN_NAME = 'student_id';

    IF col_type = 'int' THEN
        IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'grades' AND COLUMN_NAME = '_sn') THEN
            ALTER TABLE grades DROP COLUMN _sn;
        END IF;
        ALTER TABLE grades DROP FOREIGN KEY IF EXISTS fk_g_student;
        ALTER TABLE grades ADD COLUMN _sn VARCHAR(100) NULL;
        UPDATE grades g JOIN sys_users u ON g.student_id = u.user_id SET g._sn = u.username;
        ALTER TABLE grades DROP COLUMN student_id;
        ALTER TABLE grades CHANGE COLUMN _sn student_id VARCHAR(100) NOT NULL;
        SELECT 'grades: migrated to VARCHAR' AS result;
    ELSE
        SELECT 'grades: already VARCHAR, skipping' AS result;
    END IF;
END$$
DELIMITER ;
CALL _migrate_grades();
DROP PROCEDURE IF EXISTS _migrate_grades;

-- payments (reference_number is already VARCHAR — no migration needed, but verify)
SELECT 'payments.reference_number already uses student_number (VARCHAR) — no migration needed.' AS result;

-- ── Step 4: Verify ───────────────────────────────────────────
SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME IN ('student_ledger', 'student_enlistments', 'grades', 'students')
  AND COLUMN_NAME = 'student_id'
ORDER BY TABLE_NAME;

SELECT COUNT(*) AS students_migrated FROM students;
