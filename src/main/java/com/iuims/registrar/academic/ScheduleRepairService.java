package com.iuims.registrar.academic;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Repairs legacy/demo schedule rows where every section was stamped onto one room (e.g. LAB-301).
 * Rebuilds conflict-free day/time slots per term; rooms are cleared to TBA.
 */
@Service
public class ScheduleRepairService {

    private static final String INSERT_STAGGERED_SLOTS = """
        INSERT INTO class_schedules (section_id, room_id, faculty_id, day_of_week, start_time, end_time, schedule_type, status)
        SELECT
            slot.section_id,
            NULL AS room_id,
            slot.faculty_id,
            MOD(slot.slot_no - 1, 5) + 1 AS day_of_week,
            CASE MOD(FLOOR((slot.slot_no - 1) / 5), 5)
                WHEN 0 THEN TIME '07:30:00'
                WHEN 1 THEN TIME '09:00:00'
                WHEN 2 THEN TIME '10:30:00'
                WHEN 3 THEN TIME '13:00:00'
                ELSE TIME '14:30:00'
            END AS start_time,
            CASE MOD(FLOOR((slot.slot_no - 1) / 5), 5)
                WHEN 0 THEN TIME '09:00:00'
                WHEN 1 THEN TIME '10:30:00'
                WHEN 2 THEN TIME '12:00:00'
                WHEN 3 THEN TIME '14:30:00'
                ELSE TIME '16:00:00'
            END AS end_time,
            CASE WHEN COALESCE(slot.lab_units, 0) > 0 THEN 'Lab' ELSE 'Lecture' END AS schedule_type,
            'OPEN' AS status
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
            WHERE cs.term_id = ?
        ) slot
        """;

    private final JdbcTemplate db;
    private final ScheduleConflictValidator conflictValidator;

    public ScheduleRepairService(JdbcTemplate db) {
        this.db = db;
        this.conflictValidator = new ScheduleConflictValidator(db);
    }

    public ConflictCounts countConflicts(int termId) {
        return new ConflictCounts(
            countRoomConflicts(termId),
            countFacultyConflicts(termId));
    }

    @Transactional
    public RepairResult repairTermSchedules(int termId) {
        Integer sections = db.queryForObject(
            "SELECT COUNT(*) FROM class_sections WHERE term_id = ?", Integer.class, termId);
        if (sections == null || sections == 0) {
            return new RepairResult(termId, 0, 0, 0, 0, 0, 0,
                "ERROR: No sections found for term " + termId + ".");
        }

        ConflictCounts before = countConflicts(termId);
        int clearedFaculty = clearOverloadedDemoFaculty(termId);
        int deleted = db.update(
            "DELETE FROM class_schedules WHERE section_id IN (" +
                "SELECT section_id FROM class_sections WHERE term_id = ?)",
            termId);
        int inserted = db.update(INSERT_STAGGERED_SLOTS, termId);
        ConflictCounts after = countConflicts(termId);

        return new RepairResult(
            termId,
            deleted,
            inserted,
            before.roomConflicts(),
            before.facultyConflicts(),
            after.roomConflicts(),
            after.facultyConflicts(),
            "SUCCESS: Repaired term " + termId + " — removed " + deleted + " schedule row(s), "
                + "created " + inserted + " staggered slot(s) (room TBA). "
                + (clearedFaculty > 0 ? "Cleared demo faculty stamp on " + clearedFaculty + " section(s). " : "")
                + "Conflicts: room " + before.roomConflicts() + "→" + after.roomConflicts()
                + ", faculty " + before.facultyConflicts() + "→" + after.facultyConflicts() + ".");
    }

    /**
     * Demo seeds often assign every section to one faculty id; that cannot be staggered into a real load.
     * Clears faculty on sections where the same faculty holds more than their teaching cap allows.
     */
    private int clearOverloadedDemoFaculty(int termId) {
        return db.update(
            "UPDATE class_sections SET faculty_id = NULL " +
                "WHERE term_id = ? AND faculty_id IN (" +
                "  SELECT faculty_id FROM (" +
                "    SELECT cs2.faculty_id " +
                "    FROM class_sections cs2 " +
                "    JOIN faculty f ON f.faculty_id = cs2.faculty_id " +
                "    WHERE cs2.term_id = ? AND cs2.faculty_id IS NOT NULL " +
                "    GROUP BY cs2.faculty_id, cs2.term_id, f.max_teaching_units " +
                "    HAVING COUNT(*) > COALESCE(NULLIF(f.max_teaching_units, 0), ?)" +
                "  ) hot" +
                ")",
            termId, termId, SchedulingPolicyConstants.DEFAULT_FACULTY_MAX_TEACHING_UNITS);
    }

    private int countRoomConflicts(int termId) {
        Integer count = db.queryForObject(
            "SELECT COUNT(*) FROM (" +
                "SELECT 1 FROM class_schedules s1 " +
                "JOIN class_schedules s2 ON s1.schedule_id < s2.schedule_id " +
                "AND s1.day_of_week = s2.day_of_week " +
                "AND s1.start_time < s2.end_time AND s1.end_time > s2.start_time " +
                "JOIN class_sections a ON a.section_id = s1.section_id " +
                "JOIN class_sections b ON b.section_id = s2.section_id AND b.term_id = a.term_id " +
                "WHERE a.term_id = ? AND s1.room_id IS NOT NULL AND s1.room_id = s2.room_id " +
                "LIMIT 100000" +
                ") x",
            Integer.class, termId);
        return count != null ? count : 0;
    }

    private int countFacultyConflicts(int termId) {
        Integer count = db.queryForObject(
            "SELECT COUNT(*) FROM (" +
                "SELECT 1 FROM class_schedules s1 " +
                "JOIN class_schedules s2 ON s1.schedule_id < s2.schedule_id " +
                "AND s1.day_of_week = s2.day_of_week " +
                "AND s1.start_time < s2.end_time AND s1.end_time > s2.start_time " +
                "JOIN class_sections a ON a.section_id = s1.section_id " +
                "JOIN class_sections b ON b.section_id = s2.section_id AND b.term_id = a.term_id " +
                "WHERE a.term_id = ? " +
                "AND COALESCE(s1.faculty_id, a.faculty_id) IS NOT NULL " +
                "AND COALESCE(s1.faculty_id, a.faculty_id) = COALESCE(s2.faculty_id, b.faculty_id) " +
                "LIMIT 100000" +
                ") x",
            Integer.class, termId);
        return count != null ? count : 0;
    }

    public record ConflictCounts(int roomConflicts, int facultyConflicts) {}

    public record RepairResult(
        int termId,
        int schedulesRemoved,
        int schedulesCreated,
        int roomConflictsBefore,
        int facultyConflictsBefore,
        int roomConflictsAfter,
        int facultyConflictsAfter,
        String message) {}
}
