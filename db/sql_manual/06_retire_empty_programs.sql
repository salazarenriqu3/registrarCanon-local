-- Manual configuration: remove six empty-curriculum programs from active offerings
-- Batch alternative: same as registrar/db/manual_patches/20260608_retire_empty_curriculum_blockers.sql
USE eacdb;

UPDATE programs SET active_status = 0
WHERE program_code IN ('BSBA', 'BSCE', 'BSCS', 'BSECE', 'BSED', 'BSMATH');

SELECT program_code, program_name, active_status
FROM programs
WHERE program_code IN ('BSBA', 'BSCE', 'BSCS', 'BSECE', 'BSED', 'BSMATH');
