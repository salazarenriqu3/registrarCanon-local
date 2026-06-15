-- ============================================================
-- SEED: Conflict-free class schedules for BSIT and BSCPE
-- Each course in a section gets a UNIQUE day+time slot
-- (no two courses share the same day AND time within one section)
-- Rev. 24 May 2026 v2
-- ============================================================
USE eacdb;
SET SQL_SAFE_UPDATES = 0;

-- ── 1. Wipe old schedules for these sections ─────────────────
DELETE cs_sch FROM class_schedules cs_sch
JOIN class_sections cs ON cs_sch.section_id = cs.section_id
WHERE cs.section_code LIKE 'BSIT-%' OR cs.section_code LIKE 'BSCPE-%';

-- ── 2. Assign ONE unique slot per course per section ─────────
-- Slot index = rn - 1 (0-indexed within each section_code group)
-- day  = (slot_idx MOD 5) + 1   → Mon=1, Tue=2, Wed=3, Thu=4, Fri=5
-- time = slot_idx DIV 5          → 0=07:30, 1=09:00, 2=10:30, 3=13:00
-- With 5 days x 4 time blocks = 20 unique slots per section (covers up to 20 subjects)
-- No second-meeting-day overlap issue since each course gets exactly ONE row.

INSERT INTO class_schedules (section_id, day_of_week, start_time, end_time)
SELECT
    cs.section_id,
    ((ranked.rn - 1) MOD 5) + 1 AS day_of_week,
    ELT(((ranked.rn - 1) DIV 5) + 1,
        '07:30:00', '09:00:00', '10:30:00', '13:00:00', '14:30:00')  AS start_time,
    ELT(((ranked.rn - 1) DIV 5) + 1,
        '09:00:00', '10:30:00', '12:00:00', '14:30:00', '16:00:00')  AS end_time
FROM (
    SELECT
        cs2.section_id,
        ROW_NUMBER() OVER (
            PARTITION BY cs2.section_code    -- rank within each section group
            ORDER BY cs2.section_id          -- deterministic order
        ) AS rn
    FROM class_sections cs2
    WHERE cs2.section_code LIKE 'BSIT-%'
       OR cs2.section_code LIKE 'BSCPE-%'
) ranked
JOIN class_sections cs ON cs.section_id = ranked.section_id;

-- ── 3. Verify — check Year 1 Sem 1 has no overlaps ──────────
SELECT
    cs.section_code,
    c.course_code,
    CASE sch.day_of_week
        WHEN 1 THEN 'Mon' WHEN 2 THEN 'Tue' WHEN 3 THEN 'Wed'
        WHEN 4 THEN 'Thu' WHEN 5 THEN 'Fri'
    END AS day,
    TIME_FORMAT(sch.start_time,'%H:%i') AS start,
    TIME_FORMAT(sch.end_time,'%H:%i')   AS end
FROM class_sections cs
JOIN courses c ON cs.course_id = c.course_id
JOIN class_schedules sch ON cs.section_id = sch.section_id
WHERE cs.section_code IN ('BSIT-1-1-A','BSIT-1-1-B')
ORDER BY cs.section_code, sch.day_of_week, sch.start_time;

SET SQL_SAFE_UPDATES = 1;
