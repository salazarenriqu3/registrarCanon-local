-- =============================================================================
-- Finance reconcile: Mark Zuckerberg 2026-0005 (Y1 → Y2 forward / overpay audit)
-- Run on eacdb. Read-only.
--
-- Expected forward to Y2 S1 (if Y1 S1 + Y1 S2 closed cleanly):
--   Y1 S1: 60183 fees − 66115 paid = −5932 credit
--   Y1 S2: 32786 fees − 19559.33 paid = +13226.67 debt
--   Combined net forward ≈ 7294.67 debt
-- =============================================================================
USE eacdb;

SET @sn = '2026-0005';
SET @sl_y1s1 = 'SL_1120242025';
SET @sl_y1s2 = 'SL_2120242025';
SET @sl_y2s1 = 'SL_1220252026';
SET @y1s1_fees = 60183.00;
SET @y1s2_fees = 32786.00;

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

SELECT 'Forward gross vs credits vs net (UI bug when gross used in TOTAL FEES)' AS section;
SELECT COALESCE(SUM(debit), 0) AS fwd_gross,
       COALESCE(SUM(credit), 0) AS fwd_credits,
       COALESCE(SUM(debit), 0) - COALESCE(SUM(credit), 0) AS fwd_net
FROM student_ledger
WHERE student_id = @sn AND transaction_type = 'FORWARDED_BALANCE';

SELECT 'Payments by term_year' AS section;
SELECT term_year, year_level, semester, status,
       COUNT(*) AS cnt, SUM(amount) AS total_amount
FROM payments WHERE reference_number = @sn
GROUP BY term_year, year_level, semester, status
ORDER BY year_level, semester, term_year;

SELECT 'Strict SL payment totals' AS section;
SELECT @sl_y1s1 AS sl, COALESCE(SUM(amount), 0) AS total
FROM payments WHERE reference_number = @sn AND status = 'COMPLETED' AND term_year = @sl_y1s1
UNION ALL
SELECT @sl_y1s2, COALESCE(SUM(amount), 0)
FROM payments WHERE reference_number = @sn AND status = 'COMPLETED' AND term_year = @sl_y1s2
UNION ALL
SELECT @sl_y2s1, COALESCE(SUM(amount), 0)
FROM payments WHERE reference_number = @sn AND status = 'COMPLETED' AND term_year = @sl_y2s1
UNION ALL
SELECT 'ALL COMPLETED', COALESCE(SUM(amount), 0)
FROM payments WHERE reference_number = @sn AND status = 'COMPLETED';

SELECT 'Expected forward from SL-tagged payments (manual reconcile)' AS section;
SELECT
  @y1s1_fees AS y1s1_fees,
  (SELECT COALESCE(SUM(amount), 0) FROM payments WHERE reference_number = @sn AND status = 'COMPLETED' AND term_year = @sl_y1s1) AS y1s1_paid,
  @y1s1_fees - (SELECT COALESCE(SUM(amount), 0) FROM payments WHERE reference_number = @sn AND status = 'COMPLETED' AND term_year = @sl_y1s1) AS y1s1_net,
  @y1s2_fees AS y1s2_fees,
  (SELECT COALESCE(SUM(amount), 0) FROM payments WHERE reference_number = @sn AND status = 'COMPLETED' AND term_year = @sl_y1s2) AS y1s2_paid,
  @y1s2_fees - (SELECT COALESCE(SUM(amount), 0) FROM payments WHERE reference_number = @sn AND status = 'COMPLETED' AND term_year = @sl_y1s2) AS y1s2_net,
  (@y1s1_fees - (SELECT COALESCE(SUM(amount), 0) FROM payments WHERE reference_number = @sn AND status = 'COMPLETED' AND term_year = @sl_y1s1))
    + (@y1s2_fees - (SELECT COALESCE(SUM(amount), 0) FROM payments WHERE reference_number = @sn AND status = 'COMPLETED' AND term_year = @sl_y1s2)) AS expected_fwd_net,
  (SELECT COALESCE(SUM(debit), 0) - COALESCE(SUM(credit), 0) FROM student_ledger WHERE student_id = @sn AND transaction_type = 'FORWARDED_BALANCE') AS actual_fwd_net;
