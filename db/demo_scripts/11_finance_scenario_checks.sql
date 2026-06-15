-- =============================================================================
-- FINANCE SCENARIO CHECKS — run after UI steps (Jun 2026 billing QA)
-- Set @sn to the student under test, or run all blocks.
-- =============================================================================
USE eacdb;
SET NAMES utf8mb4 COLLATE utf8mb4_general_ci;

-- ── A) Juan 2026-0028 — Student Manager / clean current term ─────────────────
SET @sn = '2026-0028';
SELECT 'A1 Juan — net FORWARDED (expect 0)' AS check_label;
SELECT COALESCE(SUM(debit),0) - COALESCE(SUM(credit),0) AS net_forwarded
FROM student_ledger WHERE student_id = @sn AND transaction_type = 'FORWARDED_BALANCE';

SELECT 'A2 Juan — duplicate sync PAYMENT rows (expect 0)' AS check_label;
SELECT COUNT(*) AS dup_sync_rows FROM student_ledger
WHERE student_id = @sn AND transaction_type = 'PAYMENT' AND description = 'Synced from enrollment payments';

SELECT 'A3 Juan — enlist block? forward >= 100 (expect 0 rows)' AS check_label;
SELECT COALESCE(SUM(debit),0) - COALESCE(SUM(credit),0) AS net_forward
FROM student_ledger WHERE student_id = @sn AND transaction_type = 'FORWARDED_BALANCE'
HAVING net_forward >= 100;

-- ── B) John 2026-0027 — forward payment math ──────────────────────────────────
SET @sn = '2026-0027';
SELECT 'B1 John — net FORWARDED before pay (expect 100)' AS check_label;
SELECT COALESCE(SUM(debit),0) - COALESCE(SUM(credit),0) AS net_forwarded
FROM student_ledger WHERE student_id = @sn AND transaction_type = 'FORWARDED_BALANCE';

-- After paying PHP 1 toward forward at Cashier, re-run:
SELECT 'B2 John — net FORWARDED after PHP 1 pay (expect 99)' AS check_label;
SELECT COALESCE(SUM(debit),0) - COALESCE(SUM(credit),0) AS net_forwarded
FROM student_ledger WHERE student_id = @sn AND transaction_type = 'FORWARDED_BALANCE';

SELECT 'B3 John — payments mirrored on ledger (no duplicate gap)' AS check_label;
SELECT
  (SELECT COALESCE(SUM(amount),0) FROM payments WHERE reference_number = @sn AND status = 'COMPLETED') AS payments_table,
  (SELECT COALESCE(SUM(credit),0) FROM student_ledger WHERE student_id = @sn
     AND transaction_type IN ('PAYMENT','INITIAL_PAYMENT')) AS ledger_payment_credits,
  (SELECT COALESCE(SUM(credit),0) FROM student_ledger WHERE student_id = @sn
     AND transaction_type = 'FORWARDED_BALANCE') AS ledger_forward_credits;

-- ── C) Jane 2026-0026 — term transition forward debt ──────────────────────────
SET @sn = '2026-0026';
SELECT 'C1 Jane — Y1 S2 assessment debits (expect ~56074)' AS check_label;
SELECT COALESCE(SUM(debit),0) AS assessment_debits
FROM student_ledger WHERE student_id = @sn
  AND transaction_type IN ('TUITION_ASSESSMENT','MISC_ASSESSMENT','OTHER_ASSESSMENT','RLE_ASSESSMENT','SUBJECT_ADD');

SELECT 'C2 Jane — term-scoped payments SL_2120242025 (expect 3000)' AS check_label;
SELECT COALESCE(SUM(amount),0) AS paid
FROM payments WHERE reference_number = @sn AND status = 'COMPLETED' AND term_year = 'SL_2120242025';

-- After Registrar term transition Y1 S2 → Y2 S1, re-run:
SELECT 'C3 Jane — net FORWARDED after transition (expect ~53074 debt, NOT credit)' AS check_label;
SELECT COALESCE(SUM(debit),0) - COALESCE(SUM(credit),0) AS net_forwarded
FROM student_ledger WHERE student_id = @sn AND transaction_type = 'FORWARDED_BALANCE';

SELECT 'C4 Jane — spurious credit? (expect 0 rows with net < -1000)' AS check_label;
SELECT student_id, COALESCE(SUM(debit),0) - COALESCE(SUM(credit),0) AS net_forward
FROM student_ledger WHERE student_id = @sn AND transaction_type = 'FORWARDED_BALANCE'
GROUP BY student_id HAVING net_forward < -1000;
