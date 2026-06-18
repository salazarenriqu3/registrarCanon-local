-- ============================================================
-- SCHOLAR INTEGRATION SETUP — Run against: registrar_db_v2
-- Adds the `payments` table and scholarship columns to sys_users
-- so the walk-in payment, ledger, and cashier windows work.
-- ============================================================

USE registrar_db_v2;

-- Step 1: Add scholarship columns to sys_users safely (Stored Procedure to bypass older MySQL errors with IF NOT EXISTS)
DROP PROCEDURE IF EXISTS AddScholarColumns;
DELIMITER //
CREATE PROCEDURE AddScholarColumns()
BEGIN
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'sys_users' AND COLUMN_NAME = 'scholarship_type' AND TABLE_SCHEMA = DATABASE()) THEN
        ALTER TABLE sys_users ADD COLUMN scholarship_type VARCHAR(20) NOT NULL DEFAULT 'NONE';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'sys_users' AND COLUMN_NAME = 'discount_percentage' AND TABLE_SCHEMA = DATABASE()) THEN
        ALTER TABLE sys_users ADD COLUMN discount_percentage DECIMAL(5,2) NOT NULL DEFAULT 0.00;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'sys_users' AND COLUMN_NAME = 'enrollment_blocked' AND TABLE_SCHEMA = DATABASE()) THEN
        ALTER TABLE sys_users ADD COLUMN enrollment_blocked TINYINT(1) NOT NULL DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'sys_users' AND COLUMN_NAME = 'semester' AND TABLE_SCHEMA = DATABASE()) THEN
        ALTER TABLE sys_users ADD COLUMN semester INT DEFAULT 1;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'sys_users' AND COLUMN_NAME = 'term_year' AND TABLE_SCHEMA = DATABASE()) THEN
        ALTER TABLE sys_users ADD COLUMN term_year VARCHAR(30) DEFAULT 'SL_1120252026';
    END IF;
END //
DELIMITER ;
CALL AddScholarColumns();
DROP PROCEDURE AddScholarColumns;

-- Step 2: Create the payments table (mirrors Jaypee21 schema, targeted at registrar_db_v2)
CREATE TABLE IF NOT EXISTS payments (
  payment_id       BIGINT          AUTO_INCREMENT PRIMARY KEY,
  transaction_id   VARCHAR(60)     NOT NULL,
  or_number        VARCHAR(20)     DEFAULT NULL,
  reference_number VARCHAR(50)     NOT NULL,       -- stores student_number (username in sys_users)
  amount           DECIMAL(12, 2)  NOT NULL DEFAULT 0.00,
  payment_method   VARCHAR(60)     DEFAULT 'Cash (OTC)',
  semester         INT             DEFAULT 1,
  year_level       INT             DEFAULT 1,
  term_year        VARCHAR(30)     DEFAULT NULL,
  remarks          VARCHAR(150)    DEFAULT NULL,
  payment_date     DATETIME        NOT NULL DEFAULT NOW(),
  status           VARCHAR(20)     NOT NULL DEFAULT 'COMPLETED',
  UNIQUE KEY uk_transaction (transaction_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Step 3: Seed a sample scholarship for testing (update with real student numbers)
-- UPDATE sys_users SET scholarship_type = 'ACADEMIC' WHERE username = '2026-0001';
-- UPDATE sys_users SET scholarship_type = 'DISCOUNT', discount_percentage = 50 WHERE username = '2026-0002';

-- ============================================================
-- DONE. Run this once, then restart the Spring Boot application.
-- ============================================================
