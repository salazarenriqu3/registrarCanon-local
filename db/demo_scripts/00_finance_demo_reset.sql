-- =============================================================================
-- FINANCE DEMO RESET — removes finance test personas (Jun 2026)
-- Run BEFORE 10_seed_finance_demo_personas.sql for a clean finance retest.
-- Does NOT touch curriculum, sections, fees, or other demo students (2026-0004, etc.).
-- =============================================================================
USE eacdb;
SET NAMES utf8mb4 COLLATE utf8mb4_general_ci;
SET FOREIGN_KEY_CHECKS = 0;
SET SQL_SAFE_UPDATES = 0;

-- Finance QA personas (2026-0026 .. 2026-0028)
DELETE FROM grades              WHERE student_id IN ('2026-0026','2026-0027','2026-0028');
DELETE FROM student_enlistments WHERE student_id IN ('2026-0026','2026-0027','2026-0028');
DELETE FROM student_ledger      WHERE student_id IN ('2026-0026','2026-0027','2026-0028');
DELETE FROM subject_logs        WHERE student_number IN ('2026-0026','2026-0027','2026-0028');
DELETE FROM payments            WHERE reference_number IN ('2026-0026','2026-0027','2026-0028');
DELETE FROM students            WHERE student_number IN ('2026-0026','2026-0027','2026-0028');
DELETE FROM sys_users           WHERE username IN ('2026-0026','2026-0027','2026-0028');
DELETE FROM applicants          WHERE reference_number IN ('DEMO-FIN-0026','DEMO-FIN-0027','DEMO-FIN-0028');

-- Legacy duplicate sync rows (safe cleanup if re-seeding after old WAR)
DELETE FROM student_ledger
WHERE student_id IN ('2026-0026','2026-0027','2026-0028')
  AND transaction_type = 'PAYMENT'
  AND description = 'Synced from enrollment payments';

SET FOREIGN_KEY_CHECKS = 1;
SET SQL_SAFE_UPDATES = 1;

SELECT 'Finance demo personas 2026-0026..0028 removed.' AS status;
