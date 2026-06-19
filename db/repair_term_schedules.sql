-- =============================================================================
-- REPAIR TERM SCHEDULES (fix LAB-301 / single-room demo stamp)
-- Removes all schedule rows for one term and rebuilds staggered day/time slots.
-- Rooms are set to TBA (NULL) so room conflicts are eliminated.
-- Faculty slots are staggered per assigned faculty within the term.
--
-- Usage:
--   SET @target_term_id = 1;   -- or active term_id from academic_terms
--   SOURCE repair_term_schedules.sql;
--
-- Safe to re-run for the same term.
-- =============================================================================
USE eacdb;
SET SQL_SAFE_UPDATES = 0;

SET @target_term_id = (
    SELECT term_id FROM academic_terms
    WHERE status IN ('Active', 'ACTIVE', 'Open', 'OPEN')
    ORDER BY term_id DESC LIMIT 1
);

SELECT @target_term_id AS repairing_term_id;

UPDATE class_sections cs
JOIN (
    SELECT cs2.faculty_id, cs2.term_id, COUNT(*) AS section_count, f.max_teaching_units
    FROM class_sections cs2
    JOIN faculty f ON f.faculty_id = cs2.faculty_id
    WHERE cs2.term_id = @target_term_id AND cs2.faculty_id IS NOT NULL
    GROUP BY cs2.faculty_id, cs2.term_id, f.max_teaching_units
    HAVING section_count > COALESCE(NULLIF(f.max_teaching_units, 0), 18)
) hot ON hot.faculty_id = cs.faculty_id AND hot.term_id = cs.term_id
SET cs.faculty_id = NULL;

DELETE FROM class_schedules
WHERE section_id IN (SELECT section_id FROM class_sections WHERE term_id = @target_term_id);

INSERT INTO class_schedules (section_id, room_id, faculty_id, day_of_week, start_time, end_time, schedule_type, status)
SELECT
    slot.section_id,
    NULL AS room_id,
    slot.faculty_id,
    MOD(slot.slot_no - 1, 5) + 1 AS day_of_week,
    CASE FLOOR((slot.slot_no - 1) / 5) MOD 5
        WHEN 0 THEN '07:30:00'
        WHEN 1 THEN '09:00:00'
        WHEN 2 THEN '10:30:00'
        WHEN 3 THEN '13:00:00'
        ELSE '14:30:00'
    END AS start_time,
    CASE FLOOR((slot.slot_no - 1) / 5) MOD 5
        WHEN 0 THEN '09:00:00'
        WHEN 1 THEN '10:30:00'
        WHEN 2 THEN '12:00:00'
        WHEN 3 THEN '14:30:00'
        ELSE '16:00:00'
    END AS end_time,
    CASE WHEN COALESCE(slot.lab_units, 0) > 0 THEN 'Lab' ELSE 'Lecture' END AS schedule_type,
    'OPEN'
FROM (
    SELECT
        cs.section_id,
        cs.faculty_id,
        c.lab_units,
        ROW_NUMBER() OVER (
            PARTITION BY cs.term_id
            ORDER BY cs.section_code, c.course_code, cs.section_id
        ) AS slot_no
    FROM class_sections cs
    JOIN courses c ON c.course_id = cs.course_id
    WHERE cs.term_id = @target_term_id
) slot;

SELECT 'sections_in_term' AS metric, COUNT(*) AS val
FROM class_sections WHERE term_id = @target_term_id
UNION ALL
SELECT 'schedule_rows', COUNT(*)
FROM class_schedules sch
JOIN class_sections cs ON cs.section_id = sch.section_id
WHERE cs.term_id = @target_term_id
UNION ALL
SELECT 'rows_with_room', COUNT(*)
FROM class_schedules sch
JOIN class_sections cs ON cs.section_id = sch.section_id
WHERE cs.term_id = @target_term_id AND sch.room_id IS NOT NULL;

SET SQL_SAFE_UPDATES = 1;
