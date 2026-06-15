-- ============================================================
-- SEED: Open sections for BSIT and BSCPE (testing only)
-- 2 sections per program per year/sem, status = 'Open'
-- Adds an active 2025-2026 academic term if missing.
-- Rev. 24 May 2026
-- ============================================================
USE eacdb;
SET FOREIGN_KEY_CHECKS = 0;
SET SQL_SAFE_UPDATES = 0;  -- required for MySQL Workbench safe mode

-- ── 1. Ensure a 2025-2026 active academic term exists ────────
INSERT INTO academic_terms (term_id, term_code, term_name, academic_year, semester_number, start_date, end_date, status, is_active)
VALUES
  (10, '1120252026', 'First Semester 2025-2026',  '2025-2026', 1, '2025-08-01', '2025-12-15', 'ACTIVE',   1),
  (11, '2120252026', 'Second Semester 2025-2026', '2025-2026', 2, '2026-01-15', '2026-05-30', 'INACTIVE', 0)
ON DUPLICATE KEY UPDATE
  status    = VALUES(status),
  is_active = VALUES(is_active);

-- Mark term 10 as the one active term
UPDATE academic_terms SET is_active = 0 WHERE term_id NOT IN (10);
UPDATE academic_terms SET status = 'ACTIVE', is_active = 1 WHERE term_id = 10;

-- ── 2. Delete old Planning sections for BSIT / BSCPE ─────────
-- (keeps only sections we recreate below with 'Open' status)
DELETE FROM class_sections
WHERE section_code LIKE 'BSIT-%' OR section_code LIKE 'BSCPE-%';

-- ── Helper: Get all BSIT courses per year/sem (curriculum_id 1 OR 15) ──
-- ── Helper: Get all BSCPE courses per year/sem (curriculum_id 16) ──────

-- ── 3. Create 2 OPEN sections per year/sem for BSIT ─────────
-- We create one row per course per section (A and B)

INSERT INTO class_sections (course_id, term_id, section_code, faculty_id, max_capacity, section_status, semester_number)
SELECT
    cc.course_id,
    10,
    CONCAT('BSIT-', cc.year_level, '-', cc.semester_number, '-A'),
    NULL,
    40,
    'Open',
    cc.semester_number
FROM curriculum_courses cc
JOIN curriculum_templates ct ON cc.curriculum_id = ct.curriculum_id
JOIN programs p ON ct.program_id = p.program_id
WHERE p.program_code = 'BSIT'
  AND ct.curriculum_id = 1
ON DUPLICATE KEY UPDATE section_status = 'Open';

INSERT INTO class_sections (course_id, term_id, section_code, faculty_id, max_capacity, section_status, semester_number)
SELECT
    cc.course_id,
    10,
    CONCAT('BSIT-', cc.year_level, '-', cc.semester_number, '-B'),
    NULL,
    40,
    'Open',
    cc.semester_number
FROM curriculum_courses cc
JOIN curriculum_templates ct ON cc.curriculum_id = ct.curriculum_id
JOIN programs p ON ct.program_id = p.program_id
WHERE p.program_code = 'BSIT'
  AND ct.curriculum_id = 1
ON DUPLICATE KEY UPDATE section_status = 'Open';

-- ── 4. Create 2 OPEN sections per year/sem for BSCPE ────────
INSERT INTO class_sections (course_id, term_id, section_code, faculty_id, max_capacity, section_status, semester_number)
SELECT
    cc.course_id,
    10,
    CONCAT('BSCPE-', cc.year_level, '-', cc.semester_number, '-A'),
    NULL,
    40,
    'Open',
    cc.semester_number
FROM curriculum_courses cc
JOIN curriculum_templates ct ON cc.curriculum_id = ct.curriculum_id
JOIN programs p ON ct.program_id = p.program_id
WHERE p.program_code = 'BSCPE'
  AND ct.curriculum_id = 16
ON DUPLICATE KEY UPDATE section_status = 'Open';

INSERT INTO class_sections (course_id, term_id, section_code, faculty_id, max_capacity, section_status, semester_number)
SELECT
    cc.course_id,
    10,
    CONCAT('BSCPE-', cc.year_level, '-', cc.semester_number, '-B'),
    NULL,
    40,
    'Open',
    cc.semester_number
FROM curriculum_courses cc
JOIN curriculum_templates ct ON cc.curriculum_id = ct.curriculum_id
JOIN programs p ON ct.program_id = p.program_id
WHERE p.program_code = 'BSCPE'
  AND ct.curriculum_id = 16
ON DUPLICATE KEY UPDATE section_status = 'Open';

-- ── 5. Verify ────────────────────────────────────────────────
SELECT
    SUBSTRING_INDEX(cs.section_code, '-', 3)    AS section_group,
    COUNT(*)                                     AS subject_count,
    cs.section_status
FROM class_sections cs
WHERE cs.section_code LIKE 'BSIT-%' OR cs.section_code LIKE 'BSCPE-%'
GROUP BY section_group, cs.section_status
ORDER BY section_group;

SET SQL_SAFE_UPDATES = 1;  -- restore safe mode
SET FOREIGN_KEY_CHECKS = 1;
