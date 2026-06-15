-- =============================================================================
-- EACDB — TEST DATA SEED SCRIPT (Mock Applicants)
-- =============================================================================
USE eacdb;

-- 1. Mock Applicants (Without Payments)
-- These applicants are in 'SUBMITTED' status and have not yet paid the downpayment.
INSERT IGNORE INTO applicants 
(reference_number, applicant_status, term_year, first_name, last_name, email, mobile, program1, created_at, updated_at) 
VALUES
('APP-2024-0001', 'QUALIFIED FOR ENROLLMENT', '1120242025', 'John', 'Doe', 'john.doe@example.com', '09171234561', 'BSIT', NOW(), NOW()),
('APP-2024-0002', 'QUALIFIED FOR ENROLLMENT', '1120242025', 'Jane', 'Smith', 'jane.smith@example.com', '09181234562', 'BSCS', NOW(), NOW()),
('APP-2024-0003', 'QUALIFIED FOR ENROLLMENT', '1120242025', 'Mark', 'Zuckerberg', 'mark.z@example.com', '09191234563', 'BSIT', NOW(), NOW()),
('APP-2024-0004', 'QUALIFIED FOR ENROLLMENT', '1120242025', 'Elon', 'Musk', 'elon.m@example.com', '09201234564', 'BSCS', NOW(), NOW()),
('APP-2024-0005', 'QUALIFIED FOR ENROLLMENT', '1120242025', 'Ada', 'Lovelace', 'ada.l@example.com', '09211234565', 'BSIT', NOW(), NOW());

-- (Optional) If you also want to simulate applicants who have uploaded documents but still need to pay:
INSERT IGNORE INTO applicants 
(reference_number, applicant_status, term_year, first_name, last_name, email, mobile, program1, form138_verified, psa_birth_cert_verified, created_at, updated_at) 
VALUES
('APP-2024-0006', 'VERIFIED', '1120242025', 'Grace', 'Hopper', 'grace.h@example.com', '09221234566', 'BSCS', 1, 1, NOW(), NOW());
