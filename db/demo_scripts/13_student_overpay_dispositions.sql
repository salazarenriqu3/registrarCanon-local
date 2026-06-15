-- Overpayment disposition audit + optional payments.direction for refund payouts.
-- Safe to run on existing eacdb before deploying updated registrar WAR.

USE eacdb;

CREATE TABLE IF NOT EXISTS student_overpay_dispositions (
    disposition_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    student_id VARCHAR(100) NOT NULL,
    source_closing_sl VARCHAR(32) NULL,
    pending_amount DECIMAL(12,2) NOT NULL,
    refunded_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    credited_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    decided_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    decided_by VARCHAR(100) NULL,
    remarks VARCHAR(255) NULL,
    KEY idx_overpay_disp_student (student_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Idempotent column add (MariaDB 10.3+ / MySQL 8.0.12+ ignore duplicate; older: run once)
SET @col_exists = (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'payments' AND COLUMN_NAME = 'direction'
);
SET @ddl = IF(@col_exists = 0,
    'ALTER TABLE payments ADD COLUMN direction VARCHAR(10) NOT NULL DEFAULT ''IN'' COMMENT ''IN=collection, OUT=refund'' AFTER status',
    'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
