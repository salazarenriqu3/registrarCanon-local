-- Student term-close snapshots for frozen historical ledger views.
-- Safe to run on an existing eacdb before deploying updated enrollment/registrar WARs.

USE eacdb;

CREATE TABLE IF NOT EXISTS student_term_closes (
    close_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    student_id VARCHAR(100) NOT NULL,
    closing_sl VARCHAR(32) NOT NULL,
    term_id INT NULL,
    assess_total DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    term_payments DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    scholar_discount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    prior_forward DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    forward_net DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    term_balance DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    closed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_student_term_close (student_id, closing_sl),
    KEY idx_student_term_closes_student (student_id),
    KEY idx_student_term_closes_term (term_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
