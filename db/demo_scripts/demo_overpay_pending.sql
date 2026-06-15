-- Demo: seed a pending overpayment for manual OPAY-R UAT (Registrar Student Manager).
-- Replace @sn with target student_number after an overpaid term close, or use as-is for a test student.

USE eacdb;

SET @sn = '2026-0001';

DELETE FROM student_ledger
WHERE student_id = @sn AND transaction_type = 'PENDING_TERM_CREDIT';

INSERT INTO student_ledger (student_id, transaction_type, description, debit, credit)
VALUES (@sn, 'PENDING_TERM_CREDIT', 'Demo prior-term overpayment (pending disposition)', 0, 2500.00);

SELECT transaction_type, description, debit, credit
FROM student_ledger
WHERE student_id = @sn
ORDER BY ledger_id DESC
LIMIT 5;
