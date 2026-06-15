-- Manual configuration: add schedule slot to ONE BSCPE Y1 block section (scheduling demo)
-- Batch alternative: registrar/db/seed_all_class_schedules.sql
-- UI alternative: /admin/classes → open section → add day/time/room
USE eacdb;

SET @term_id = (SELECT term_id FROM academic_terms WHERE term_code = '2120242025' LIMIT 1);
SET @section_id = (
    SELECT cs.section_id FROM class_sections cs
    JOIN courses c ON c.course_id = cs.course_id
    WHERE cs.term_id = @term_id AND cs.section_code = 'BSCPE-1-2-A'
    LIMIT 1
);
SET @room_id = (SELECT room_id FROM rooms WHERE active_status = 1 ORDER BY room_id LIMIT 1);

INSERT INTO class_schedules (section_id, day_of_week, start_time, end_time, room_id, schedule_type)
SELECT @section_id, 1, '07:30:00', '09:00:00', @room_id, 'Lecture'
FROM DUAL
WHERE @section_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM class_schedules WHERE section_id = @section_id);

SELECT cs.section_code, c.course_code,
       sch.day_of_week, sch.start_time, sch.end_time,
       COALESCE(r.room_code, 'TBA') AS room
FROM class_sections cs
JOIN courses c ON c.course_id = cs.course_id
LEFT JOIN class_schedules sch ON sch.section_id = cs.section_id
LEFT JOIN rooms r ON r.room_id = sch.room_id
WHERE cs.section_id = @section_id;
