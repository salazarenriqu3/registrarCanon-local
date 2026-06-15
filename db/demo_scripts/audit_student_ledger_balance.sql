-- Audit why "Balance Forwarded" looks too large after term change (e.g. 2026-0004).
-- Run in MySQL Workbench on eacdb.

SET @sn = '2026-0004';

SELECT 'Ledger by type' AS section;
SELECT transaction_type,
       COALESCE(SUM(debit), 0) AS total_debit,
       COALESCE(SUM(credit), 0) AS total_credit,
       COALESCE(SUM(debit), 0) - COALESCE(SUM(credit), 0) AS net
FROM student_ledger
WHERE student_id = @sn
GROUP BY transaction_type
ORDER BY transaction_type;

SELECT 'Net ledger (should match cashier forwarded if only FORWARDED row remains)' AS section;
SELECT COALESCE(SUM(debit), 0) - COALESCE(SUM(credit), 0) AS net_ledger
FROM student_ledger
WHERE student_id = @sn;

SELECT 'Forward gross vs credits vs net (totals must use fwd_net, not fwd_gross)' AS section;
SELECT COALESCE(SUM(debit), 0) AS fwd_gross,
       COALESCE(SUM(credit), 0) AS fwd_credits,
       COALESCE(SUM(debit), 0) - COALESCE(SUM(credit), 0) AS fwd_net
FROM student_ledger
WHERE student_id = @sn AND transaction_type = 'FORWARDED_BALANCE';

SELECT 'Payments table (by year/sem)' AS section;
SELECT year_level, semester, term_year, SUM(amount) AS paid
FROM payments
WHERE reference_number = @sn AND status = 'COMPLETED'
GROUP BY year_level, semester, term_year
ORDER BY year_level, semester;

-- Optional: correct an inflated single FORWARDED_BALANCE row after a bad term rollover
-- (only if you know the true amount, e.g. 99.00)
-- UPDATE student_ledger SET debit = 99.00
-- WHERE student_id = @sn AND transaction_type = 'FORWARDED_BALANCE';
