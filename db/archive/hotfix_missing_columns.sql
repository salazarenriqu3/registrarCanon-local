-- ============================================================
-- HOTFIX: Add columns missing from eacdb tables that the
-- enrollment3 JPA entities expect (rev. 24 May 2026)
-- Updated: 25 May 2026 — added students table coverage
-- ============================================================
USE eacdb;

-- ── sys_users: columns required by Student.java (legacy bridge) ─
ALTER TABLE sys_users
    ADD COLUMN IF NOT EXISTS scholarship_amount   DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    ADD COLUMN IF NOT EXISTS scholarship_approved TINYINT(1)   NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS section_group        VARCHAR(10)  DEFAULT NULL;

-- ── students: same columns (authoritative source after migration) ─
-- Run hotfix_student_table_migration.sql first if the students table doesn't exist yet.
ALTER TABLE students
    ADD COLUMN IF NOT EXISTS scholarship_amount   DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    ADD COLUMN IF NOT EXISTS scholarship_approved TINYINT(1)   NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS section_group        VARCHAR(10)  DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS password             VARCHAR(255) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS role                 VARCHAR(30)  NOT NULL DEFAULT 'STUDENT';

-- ── payments: columns required by Payment.java ──────────────────
ALTER TABLE payments
    ADD COLUMN IF NOT EXISTS bank_name    VARCHAR(100) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS check_number VARCHAR(60)  DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS check_date   DATETIME     DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS cashier_name VARCHAR(100) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS date_created DATETIME     DEFAULT CURRENT_TIMESTAMP;

-- ── courses: onlist alias for active_status ──────────────────────
-- The enrollment SQL queries use c.onlist = 1; the schema uses active_status.
-- We add onlist as a stored generated column so both names work.
ALTER TABLE courses
    ADD COLUMN IF NOT EXISTS onlist     TINYINT(1) GENERATED ALWAYS AS (active_status) STORED,
    ADD COLUMN IF NOT EXISTS lec_units  INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS lab_units  INT NOT NULL DEFAULT 0;


-- ── Verify ───────────────────────────────────────────────────────
SELECT 'sys_users' as tbl, COLUMN_NAME, COLUMN_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'eacdb'
  AND TABLE_NAME   = 'sys_users'
  AND COLUMN_NAME IN ('scholarship_amount','scholarship_approved','section_group')
UNION ALL
SELECT 'students', COLUMN_NAME, COLUMN_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'eacdb'
  AND TABLE_NAME   = 'students'
  AND COLUMN_NAME IN ('scholarship_amount','scholarship_approved','section_group','password','role')
UNION ALL
SELECT 'payments', COLUMN_NAME, COLUMN_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'eacdb'
  AND TABLE_NAME   = 'payments'
  AND COLUMN_NAME IN ('bank_name','check_number','check_date','cashier_name','date_created')
UNION ALL
SELECT 'courses', COLUMN_NAME, COLUMN_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'eacdb'
  AND TABLE_NAME   = 'courses'
  AND COLUMN_NAME IN ('onlist');
