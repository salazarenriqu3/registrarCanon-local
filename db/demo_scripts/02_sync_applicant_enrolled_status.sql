-- Backfill: applicants still ADMITTED while students.admission_status is ENROLLED.
-- Run once on shared eacdb after deploying registrar JaypeeIntegrationService sync.
-- Safe to re-run (only updates ADMITTED rows linked to ENROLLED students).

UPDATE applicants a
INNER JOIN students s ON s.reference_number = a.reference_number
SET a.applicant_status = 'ENROLLED',
    a.updated_at = NOW()
WHERE s.admission_status = 'ENROLLED'
  AND a.applicant_status = 'ADMITTED';

SELECT a.reference_number,
       a.applicant_status,
       s.student_number,
       s.admission_status
FROM applicants a
INNER JOIN students s ON s.reference_number = a.reference_number
WHERE s.admission_status = 'ENROLLED'
  AND a.applicant_status <> 'ENROLLED'
LIMIT 20;
