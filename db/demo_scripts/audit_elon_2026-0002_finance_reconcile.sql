-- =============================================================================
-- Finance reconcile: Elon Musk 2026-0002 (Y1 S2 → Y2 S1 forward / overpay audit)
-- Run on eacdb after reproducing the issue. Read-only.
-- =============================================================================
USE eacdb;

SET @sn = '2026-0002';
SET @sl_y1s1 = 'SL_1120242025';
SET @sl_y1s2 = 'SL_2120242025';
SET @sl_y2s1 = 'SL_1220252026';

SELECT 'Student standing' AS section;
SELECT student_number, program_code, year_level, semester, term_year, admission_status, student_type
FROM students WHERE student_number = @sn;

SELECT 'Ledger by transaction_type' AS section;
SELECT transaction_type,
       COALESCE(SUM(debit), 0) AS debits,
       COALESCE(SUM(credit), 0) AS credits,
       COALESCE(SUM(debit), 0) - COALESCE(SUM(credit), 0) AS net
FROM student_ledger WHERE student_id = @sn
GROUP BY transaction_type ORDER BY transaction_type;

SELECT 'FORWARDED_BALANCE net (negative = credit forward)' AS section;
SELECT COALESCE(SUM(debit),0) AS fwd_debit,
       COALESCE(SUM(credit),0) AS fwd_credit,
       COALESCE(SUM(debit),0) - COALESCE(SUM(credit),0) AS fwd_net
FROM student_ledger WHERE student_id = @sn AND transaction_type = 'FORWARDED_BALANCE';

SELECT 'Payments by term_year' AS section;
SELECT term_year, year_level, semester, status,
       COUNT(*) AS cnt, SUM(amount) AS total_amount
FROM payments WHERE reference_number = @sn
GROUP BY term_year, year_level, semester, status
ORDER BY year_level, semester, term_year;

SELECT 'Strict SL payment totals' AS section;
SELECT @sl_y1s1 AS sl, COALESCE(SUM(amount),0) AS total
FROM payments WHERE reference_number = @sn AND status = 'COMPLETED' AND term_year = @sl_y1s1
UNION ALL
SELECT @sl_y1s2, COALESCE(SUM(amount),0)
FROM payments WHERE reference_number = @sn AND status = 'COMPLETED' AND term_year = @sl_y1s2
UNION ALL
SELECT 'ALL COMPLETED', COALESCE(SUM(amount),0)
FROM payments WHERE reference_number = @sn AND status = 'COMPLETED';

SELECT 'Expected Y1 S2 close forward (manual check)' AS section;
SELECT
  63115.00 AS y1s1_debt_if_closed,
  60183.00 AS y1s2_fees_approx,
  (SELECT COALESCE(SUM(amount),0) FROM payments WHERE reference_number=@sn AND status='COMPLETED' AND term_year=@sl_y1s2) AS y1s2_payments_strict,
  63115.00 + 60183.00
    - (SELECT COALESCE(SUM(amount),0) FROM payments WHERE reference_number=@sn AND status='COMPLETED' AND term_year=@sl_y1s2) AS expected_debt_forward,
  (SELECT COALESCE(SUM(debit),0)-COALESCE(SUM(credit),0) FROM student_ledger WHERE student_id=@sn AND transaction_type='FORWARDED_BALANCE') AS actual_fwd_net;
