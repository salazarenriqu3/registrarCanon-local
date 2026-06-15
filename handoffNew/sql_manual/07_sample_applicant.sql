-- Manual configuration: one applicant + payment for live admission demo (Session A9/A10)
-- UI: Enrollment walk-in pay → Registrar admission acceptance
USE eacdb;

SET @ref = 'DEMO-APP-001';

DELETE FROM payments WHERE reference_number = @ref;
DELETE FROM applicants WHERE reference_number = @ref;

INSERT INTO applicants (reference_number, applicant_status, first_name, last_name, email, program1)
VALUES (@ref, 'QUALIFIED FOR ENROLLMENT', 'Demo', 'Applicant', 'demo.applicant@test.eac.ph', 'BSCPE');

INSERT INTO payments (transaction_id, reference_number, amount, payment_method, status, payment_date)
VALUES ('DEMO-PAY-001', @ref, 5000, 'Cash', 'COMPLETED', NOW());

SELECT reference_number, first_name, last_name, program1, applicant_status FROM applicants WHERE reference_number = @ref;
SELECT reference_number, amount, status FROM payments WHERE reference_number = @ref;

-- Y1 admit URL: /admin/admission-acceptance?refNo=DEMO-APP-001
-- For Y2+ demo: create DEMO-APP-Y2 with year level 2 in UI
