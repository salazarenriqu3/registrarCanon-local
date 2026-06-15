-- =============================================================================
-- REG FORM HISTORY UAT SEED
--
-- Purpose:
--   Populate the registrar reg-form history report with a small, predictable
--   event trail for demo/student-profile verification.
--
-- Safe/idempotent:
--   Re-running this script resets only the demo student's reg-form events.
--
-- Demo student:
--   Student number: 26-1-00001
-- =============================================================================

USE eacdb;

CREATE TABLE IF NOT EXISTS student_reg_form_events (
    event_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    student_number VARCHAR(100) NOT NULL,
    event_type VARCHAR(60) NOT NULL,
    purpose VARCHAR(160) NOT NULL,
    related_request_id BIGINT NULL,
    remarks VARCHAR(500) NULL,
    triggered_by VARCHAR(100) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_srfe_student (student_number, created_at),
    KEY idx_srfe_type (event_type, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET @student_number := '26-1-00001';

DELETE FROM student_reg_form_events
WHERE student_number = @student_number;

INSERT INTO student_reg_form_events
    (student_number, event_type, purpose, related_request_id, remarks, triggered_by)
VALUES
    (
        @student_number,
        'CURRICULUM_ASSIGNED',
        'Registrar curriculum assignment updated',
        NULL,
        'Curriculum assigned for demo student profile.',
        'registrar'
    ),
    (
        @student_number,
        'TRANSFER_CREDIT',
        'Transfer/TOR credit recorded',
        NULL,
        'Credited AECO 11 from prior school.',
        'registrar'
    ),
    (
        @student_number,
        'OVERPAY_CREDIT',
        'Overpayment disposition recorded',
        NULL,
        'Applied pending overpayment as account credit.',
        'cashier'
    ),
    (
        @student_number,
        'SUBJECT_ADD',
        'Registrar subject add completed',
        NULL,
        'Added UPR1 11 via demo section.',
        'registrar'
    ),
    (
        @student_number,
        'WITHDRAWAL_APPROVED',
        'Registration form updated after formal withdrawal',
        1001,
        'Demo withdrawal approved and removed from load.',
        'admin'
    );

