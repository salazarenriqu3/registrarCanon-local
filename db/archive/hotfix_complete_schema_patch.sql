-- ============================================================
-- HOTFIX: Complete Schema Patch (rev. 25 May 2026)
-- Replaces: hotfix_missing_columns.sql
--           hotfix_student_table_migration.sql
--
-- SAFE TO RUN ON:
--   ✅ Fresh PC with no prior data (empty tables)
--   ✅ Existing system with student data (idempotent)
--   ✅ Re-run any number of times (IF NOT EXISTS / type guards)
--
-- RUN ORDER: After 01_schema + 02_seed + 03_seed_applicants
--            (before starting Tomcat for the first time)
-- ============================================================
USE eacdb;

SET SQL_SAFE_UPDATES = 0;

-- ════════════════════════════════════════════════════════════
-- PART A — Missing columns on legacy tables
-- (safe: ADD COLUMN IF NOT EXISTS never errors on fresh schema)
-- ════════════════════════════════════════════════════════════

-- ── sys_users: columns required by Student.java ─────────────
ALTER TABLE sys_users
    ADD COLUMN IF NOT EXISTS scholarship_amount   DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    ADD COLUMN IF NOT EXISTS scholarship_approved TINYINT(1)   NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS section_group        VARCHAR(10)  DEFAULT NULL;

-- ── payments: columns required by Payment.java ──────────────
ALTER TABLE payments
    ADD COLUMN IF NOT EXISTS bank_name    VARCHAR(100) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS check_number VARCHAR(60)  DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS check_date   DATETIME     DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS cashier_name VARCHAR(100) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS date_created DATETIME     DEFAULT CURRENT_TIMESTAMP;

-- ── courses: onlist alias for active_status ──────────────────
ALTER TABLE courses
    ADD COLUMN IF NOT EXISTS onlist    TINYINT(1) GENERATED ALWAYS AS (active_status) STORED,
    ADD COLUMN IF NOT EXISTS lec_units INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS lab_units INT NOT NULL DEFAULT 0;


-- ════════════════════════════════════════════════════════════
-- PART B — Create `students` table
-- (safe: CREATE TABLE IF NOT EXISTS never errors on fresh schema)
-- ════════════════════════════════════════════════════════════

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

-- ── Guard: add any columns that might be missing if the table ─
-- already existed from a previous partial run
ALTER TABLE students
    ADD COLUMN IF NOT EXISTS scholarship_amount   DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    ADD COLUMN IF NOT EXISTS scholarship_approved TINYINT(1)   NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS section_group        VARCHAR(10)  DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS password             VARCHAR(255) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS role                 VARCHAR(30)  NOT NULL DEFAULT 'STUDENT';


-- ════════════════════════════════════════════════════════════
-- PART C — Migrate student rows from sys_users → students
-- (safe: INSERT IGNORE silently skips already-migrated rows;
--  on a fresh PC with no students this inserts 0 rows — OK)
-- ════════════════════════════════════════════════════════════

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


-- ════════════════════════════════════════════════════════════
-- PART D — Migrate transactional FK columns from INT to VARCHAR
--
-- Each procedure:
--   1. Checks if student_id is still INT (skips if already VARCHAR)
--   2. Drops FK/unique constraints first (required before ALTER)
--   3. Adds a temp _sn VARCHAR column
--   4. Backfills via JOIN with sys_users (0 rows on fresh PC — OK)
--   5. Deletes any rows where _sn is NULL (orphaned records)
--   6. Drops old INT column, renames _sn → student_id
--   7. Restores unique keys where needed
-- ════════════════════════════════════════════════════════════

-- ── student_ledger ───────────────────────────────────────────
DROP PROCEDURE IF EXISTS _migrate_ledger;
DELIMITER $$
CREATE PROCEDURE _migrate_ledger()
BEGIN
    DECLARE col_type VARCHAR(20);
    SELECT DATA_TYPE INTO col_type
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME   = 'student_ledger'
      AND COLUMN_NAME  = 'student_id';

    IF col_type = 'int' THEN
        IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'student_ledger' AND COLUMN_NAME = '_sn') THEN
            ALTER TABLE student_ledger DROP COLUMN _sn;
        END IF;
        ALTER TABLE student_ledger DROP FOREIGN KEY IF EXISTS fk_ledger_student;
        ALTER TABLE student_ledger ADD COLUMN _sn VARCHAR(100) NULL;
        UPDATE student_ledger l
               JOIN sys_users u ON l.student_id = u.user_id
           SET l._sn = u.username;
        -- Remove orphaned rows that had no matching sys_users entry
        DELETE FROM student_ledger WHERE _sn IS NULL;
        ALTER TABLE student_ledger DROP COLUMN student_id;
        ALTER TABLE student_ledger CHANGE COLUMN _sn student_id VARCHAR(100) NOT NULL;
        SELECT 'student_ledger migrated INT→VARCHAR' AS migration_result;
    ELSE
        SELECT 'student_ledger already VARCHAR — skipped' AS migration_result;
    END IF;
END$$
DELIMITER ;
CALL _migrate_ledger();
DROP PROCEDURE IF EXISTS _migrate_ledger;

-- ── student_enlistments ──────────────────────────────────────
DROP PROCEDURE IF EXISTS _migrate_enlistments;
DELIMITER $$
CREATE PROCEDURE _migrate_enlistments()
BEGIN
    DECLARE col_type VARCHAR(20);
    SELECT DATA_TYPE INTO col_type
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME   = 'student_enlistments'
      AND COLUMN_NAME  = 'student_id';

    IF col_type = 'int' THEN
        IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'student_enlistments' AND COLUMN_NAME = '_sn') THEN
            ALTER TABLE student_enlistments DROP COLUMN _sn;
        END IF;
        ALTER TABLE student_enlistments DROP FOREIGN KEY IF EXISTS fk_se_student;
        ALTER TABLE student_enlistments DROP KEY IF EXISTS uq_student_course;
        ALTER TABLE student_enlistments ADD COLUMN _sn VARCHAR(100) NULL;
        UPDATE student_enlistments e
               JOIN sys_users u ON e.student_id = u.user_id
           SET e._sn = u.username;
        -- Remove orphaned rows (no matching student in sys_users)
        DELETE FROM student_enlistments WHERE _sn IS NULL;
        ALTER TABLE student_enlistments DROP COLUMN student_id;
        ALTER TABLE student_enlistments CHANGE COLUMN _sn student_id VARCHAR(100) NOT NULL;
        ALTER TABLE student_enlistments ADD INDEX idx_se_student_course (student_id, course_id);
        SELECT 'student_enlistments migrated INT→VARCHAR' AS migration_result;
    ELSE
        SELECT 'student_enlistments already VARCHAR — skipped' AS migration_result;
    END IF;
END$$
DELIMITER ;
CALL _migrate_enlistments();
DROP PROCEDURE IF EXISTS _migrate_enlistments;

-- ── grades ───────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS _migrate_grades;
DELIMITER $$
CREATE PROCEDURE _migrate_grades()
BEGIN
    DECLARE col_type VARCHAR(20);
    SELECT DATA_TYPE INTO col_type
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME   = 'grades'
      AND COLUMN_NAME  = 'student_id';

    IF col_type = 'int' THEN
        IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'grades' AND COLUMN_NAME = '_sn') THEN
            ALTER TABLE grades DROP COLUMN _sn;
        END IF;
        ALTER TABLE grades DROP FOREIGN KEY IF EXISTS fk_g_student;
        ALTER TABLE grades ADD COLUMN _sn VARCHAR(100) NULL;
        UPDATE grades g
               JOIN sys_users u ON g.student_id = u.user_id
           SET g._sn = u.username;
        -- Remove orphaned rows (no matching student in sys_users)
        DELETE FROM grades WHERE _sn IS NULL;
        ALTER TABLE grades DROP COLUMN student_id;
        ALTER TABLE grades CHANGE COLUMN _sn student_id VARCHAR(100) NOT NULL;
        SELECT 'grades migrated INT→VARCHAR' AS migration_result;
    ELSE
        SELECT 'grades already VARCHAR — skipped' AS migration_result;
    END IF;
END$$
DELIMITER ;
CALL _migrate_grades();
DROP PROCEDURE IF EXISTS _migrate_grades;

-- ── student_waitlist ─────────────────────────────────────────
DROP PROCEDURE IF EXISTS _migrate_waitlist;
DELIMITER $$
CREATE PROCEDURE _migrate_waitlist()
BEGIN
    DECLARE col_type VARCHAR(20);
    SELECT DATA_TYPE INTO col_type
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME   = 'student_waitlist'
      AND COLUMN_NAME  = 'student_id';

    IF col_type = 'int' THEN
        IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'student_waitlist' AND COLUMN_NAME = '_sn') THEN
            ALTER TABLE student_waitlist DROP COLUMN _sn;
        END IF;
        ALTER TABLE student_waitlist DROP FOREIGN KEY IF EXISTS fk_wl_student;
        ALTER TABLE student_waitlist ADD COLUMN _sn VARCHAR(100) NULL;
        UPDATE student_waitlist w
               JOIN sys_users u ON w.student_id = u.user_id
           SET w._sn = u.username;
        DELETE FROM student_waitlist WHERE _sn IS NULL;
        ALTER TABLE student_waitlist DROP COLUMN student_id;
        ALTER TABLE student_waitlist CHANGE COLUMN _sn student_id VARCHAR(100) NOT NULL;
        SELECT 'student_waitlist migrated INT→VARCHAR' AS migration_result;
    ELSE
        SELECT 'student_waitlist already VARCHAR — skipped' AS migration_result;
    END IF;
END$$
DELIMITER ;
CALL _migrate_waitlist();
DROP PROCEDURE IF EXISTS _migrate_waitlist;

-- payments.reference_number is already VARCHAR — no migration needed.
SELECT 'payments: no migration needed (reference_number already VARCHAR)' AS migration_result;


-- ════════════════════════════════════════════════════════════
-- PART E — Verification (always safe to run)
-- ════════════════════════════════════════════════════════════

-- Check 1: Transactional columns should all be varchar now
SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    CASE WHEN DATA_TYPE = 'varchar' THEN '✅ OK' ELSE '❌ STILL INT — migration failed' END AS status
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME IN ('student_ledger', 'student_enlistments', 'grades', 'student_waitlist')
  AND COLUMN_NAME  = 'student_id'
ORDER BY TABLE_NAME;

-- Check 2: students table row count
SELECT
    COUNT(*)  AS students_count,
    CASE WHEN COUNT(*) = 0 THEN 'Fresh PC (no students yet — OK)' ELSE 'Students migrated' END AS note
FROM students;

-- Check 3: Missing columns verification
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND (
      (TABLE_NAME = 'sys_users'  AND COLUMN_NAME IN ('scholarship_amount','section_group'))
   OR (TABLE_NAME = 'payments'   AND COLUMN_NAME IN ('bank_name','cashier_name'))
   OR (TABLE_NAME = 'courses'    AND COLUMN_NAME  = 'onlist')
   OR (TABLE_NAME = 'students'   AND COLUMN_NAME IN ('student_number','role'))
  )
ORDER BY TABLE_NAME, COLUMN_NAME;
