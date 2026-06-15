-- Remove spurious FORWARDED_BALANCE created by drop/resync (same-term assess delta, not prior-term debt).
-- Example: Clarissa Reyes 2026-0003 after dropping 1 unit (1483 = one unit cost).
USE eacdb;

SET @sn = '2026-0003';

SELECT 'BEFORE' AS step, transaction_type, description, debit, credit
FROM student_ledger
WHERE student_id = @sn AND transaction_type = 'FORWARDED_BALANCE';

DELETE FROM student_ledger
WHERE student_id = @sn
  AND transaction_type = 'FORWARDED_BALANCE'
  AND description LIKE '%uncleared assessment%';

-- If any forward row remains with no prior term, clear first-term spurious forward:
DELETE FROM student_ledger
WHERE student_id = @sn
  AND transaction_type = 'FORWARDED_BALANCE'
  AND debit > 0
  AND debit < 5000
  AND NOT EXISTS (
    SELECT 1 FROM payments p
    WHERE p.reference_number = @sn AND p.status = 'COMPLETED'
      AND p.term_year <> (SELECT term_year FROM students WHERE student_number = @sn LIMIT 1)
  );

SELECT 'AFTER' AS step,
       COALESCE(SUM(debit),0) - COALESCE(SUM(credit),0) AS fwd_net
FROM student_ledger WHERE student_id = @sn AND transaction_type = 'FORWARDED_BALANCE';
