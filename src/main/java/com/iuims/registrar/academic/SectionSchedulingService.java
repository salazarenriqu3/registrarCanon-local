package com.iuims.registrar.academic;

import com.iuims.registrar.faculty.FacultyLoadService;
import com.iuims.registrar.faculty.FacultyProvisioningService;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Central gate for registrar section scheduling: conflicts, faculty unit caps, block faculty distribution.
 */
@Service
public class SectionSchedulingService {

    private static final int[][] BLOCK_SLOT_TEMPLATE = {
        {1, 7, 30, 9, 0},
        {1, 9, 0, 10, 30},
        {2, 7, 30, 9, 0},
        {2, 9, 0, 10, 30},
        {3, 7, 30, 9, 0},
        {3, 9, 0, 10, 30},
        {4, 7, 30, 9, 0},
        {4, 9, 0, 10, 30},
        {5, 7, 30, 9, 0},
        {5, 9, 0, 10, 30},
        {6, 8, 0, 10, 0},
        {6, 10, 0, 12, 0}
    };

    private final JdbcTemplate db;
    private final ScheduleConflictValidator conflictValidator;
    private final FacultyLoadService facultyLoadService;
    private final FacultyProvisioningService facultyProvisioningService;

    public SectionSchedulingService(JdbcTemplate db,
                                    FacultyLoadService facultyLoadService,
                                    FacultyProvisioningService facultyProvisioningService) {
        this.db = db;
        this.conflictValidator = new ScheduleConflictValidator(db);
        this.facultyLoadService = facultyLoadService;
        this.facultyProvisioningService = facultyProvisioningService;
    }

    public String validateNewScheduleSlot(int sectionId, Integer facultyId, Integer roomId,
                                          int dayOfWeek, LocalTime start, LocalTime end) {
        return conflictValidator.validateNewSlot(sectionId, facultyId, roomId, dayOfWeek, start, end);
    }

    /**
     * Assign or clear faculty on a section with schedule conflict + unit cap enforcement.
     */
    public String assignFaculty(int sectionId, Integer facultyId) {
        if (facultyId == null || facultyId <= 0) {
            db.update("UPDATE class_sections SET faculty_id = NULL WHERE section_id = ?", sectionId);
            db.update("UPDATE class_schedules SET faculty_id = NULL WHERE section_id = ?", sectionId);
            return "SUCCESS";
        }
        int termId = sectionTermId(sectionId);
        if (termId <= 0) {
            return "ERROR: Section not found.";
        }
        String scheduleConflict = conflictValidator.validateFacultyAssignment(sectionId, facultyId);
        if (scheduleConflict != null) {
            return "ERROR: " + scheduleConflict;
        }
        if (facultyLoadService.wouldExceedUnitCap(facultyId, termId, sectionId)) {
            Map<String, Object> summary = facultyLoadService.getFacultyLoadSummary(facultyId, termId);
            return "ERROR: Assignment would exceed faculty unit cap ("
                + summary.get("total_load_units") + "/" + summary.get("max_teaching_units") + " units).";
        }
        try {
            facultyLoadService.assignFacultyToSection(sectionId, facultyId);
            return "SUCCESS";
        } catch (IllegalArgumentException ex) {
            return "ERROR: " + ex.getMessage();
        }
    }

    /**
     * Validates that assigning one faculty to every course in a block would not exceed the teaching cap.
     */
    public String validateSingleFacultyForBlock(int termId, int facultyId, int curriculumId,
                                                int yearLevel, int semester) {
        if (facultyId <= 0) {
            return null;
        }
        double blockUnits = sumCurriculumUnits(curriculumId, yearLevel, semester);
        double currentLoad = facultyLoadService.getFacultyLoadSummary(facultyId, termId)
            .get("total_load_units") instanceof Number n ? n.doubleValue() : 0;
        int maxUnits = facultyLoadService.getFacultyLoadSummary(facultyId, termId)
            .get("max_teaching_units") instanceof Number n ? n.intValue()
            : SchedulingPolicyConstants.DEFAULT_FACULTY_MAX_TEACHING_UNITS;
        if (currentLoad + blockUnits > maxUnits) {
            return "ERROR: Block requires " + blockUnits + " units but faculty "
                + facultyId + " only has " + Math.max(0, maxUnits - currentLoad)
                + " remaining (" + currentLoad + "/" + maxUnits + "). "
                + "System will auto-distribute across available/provisioned faculty.";
        }
        return null;
    }

    /**
     * Assigns block courses to faculty without exceeding unit caps; provisions faculty when needed.
     */
    @Transactional
    public FacultyDistributionResult distributeBlockFaculty(int blockId, Integer preferredFacultyId) {
        facultyProvisioningService.ensureFacultyTeachingDefaults();
        Map<String, Object> block = db.queryForMap(
            "SELECT term_id, program_code, year_level, semester_number, faculty_id FROM block_offerings WHERE block_id = ?",
            blockId);
        int termId = ((Number) block.get("term_id")).intValue();
        String programCode = String.valueOf(block.get("program_code"));
        Integer departmentId = facultyProvisioningService.resolveProgramDepartmentId(programCode);

        List<Map<String, Object>> sections = db.queryForList(
            "SELECT cs.section_id, " +
                "CASE WHEN c.is_coordinator_based = 1 AND c.coordinator_equivalent_units IS NOT NULL " +
                "  THEN c.coordinator_equivalent_units ELSE c.credit_units END AS effective_units, " +
                "c.course_code " +
                "FROM class_sections cs JOIN courses c ON c.course_id = cs.course_id " +
                "WHERE cs.block_id = ? ORDER BY c.course_code, cs.section_id",
            blockId);

        int preferred = preferredFacultyId != null && preferredFacultyId > 0
            ? preferredFacultyId
            : block.get("faculty_id") instanceof Number n ? n.intValue() : 0;

        List<String> notes = new ArrayList<>();
        int assigned = 0;
        int provisioned = 0;

        for (Map<String, Object> row : sections) {
            int sectionId = ((Number) row.get("section_id")).intValue();
            double units = row.get("effective_units") instanceof Number n ? n.doubleValue() : 0;
            String courseCode = String.valueOf(row.get("course_code"));

            Integer targetFaculty = null;
            if (preferred > 0 && !facultyLoadService.wouldExceedUnitCap(preferred, termId, sectionId)) {
                String conflict = conflictValidator.validateFacultyAssignment(sectionId, preferred);
                if (conflict == null) {
                    targetFaculty = preferred;
                }
            }
            if (targetFaculty == null) {
                Integer beforeCount = countAutoFaculty(departmentId);
                targetFaculty = facultyProvisioningService.findOrProvisionFacultyWithCapacity(
                    departmentId, termId, units);
                if (countAutoFaculty(departmentId) > beforeCount) {
                    provisioned++;
                    notes.add("Provisioned faculty for " + courseCode);
                }
            }
            String result = assignFaculty(sectionId, targetFaculty);
            if (result.startsWith("ERROR")) {
                notes.add(courseCode + ": " + result.substring(7));
            } else {
                assigned++;
            }
        }
        return new FacultyDistributionResult(assigned, provisioned, notes);
    }

    /**
     * Stagger time slots for block sections without rooms (TBA) so intra-block overlaps are avoided.
     */
    @Transactional
    public BlockScheduleResult autoAssignBlockTimeSlots(int blockId) {
        List<Map<String, Object>> sections = db.queryForList(
            "SELECT cs.section_id FROM class_sections cs " +
                "WHERE cs.block_id = ? AND NOT EXISTS (" +
                "  SELECT 1 FROM class_schedules sch WHERE sch.section_id = cs.section_id" +
                ") ORDER BY cs.section_id",
            blockId);
        int slotIndex = 0;
        int created = 0;
        List<String> errors = new ArrayList<>();
        for (Map<String, Object> row : sections) {
            int sectionId = ((Number) row.get("section_id")).intValue();
            Integer facultyId = sectionFacultyId(sectionId);
            boolean placed = false;
            for (int attempt = 0; attempt < BLOCK_SLOT_TEMPLATE.length; attempt++) {
                int[] slot = BLOCK_SLOT_TEMPLATE[(slotIndex + attempt) % BLOCK_SLOT_TEMPLATE.length];
                LocalTime start = LocalTime.of(slot[1], slot[2]);
                LocalTime end = LocalTime.of(slot[3], slot[4]);
                String conflict = conflictValidator.validateNewSlot(
                    sectionId, facultyId, null, slot[0], start, end);
                if (conflict == null) {
                    db.update(
                        "INSERT INTO class_schedules (section_id, faculty_id, day_of_week, start_time, end_time, room_id, schedule_type, status) " +
                            "VALUES (?, ?, ?, ?, ?, NULL, 'Lecture', 'OPEN')",
                        sectionId, facultyId, slot[0], start, end);
                    created++;
                    slotIndex = (slotIndex + attempt + 1) % BLOCK_SLOT_TEMPLATE.length;
                    placed = true;
                    break;
                }
            }
            if (!placed) {
                errors.add("Section " + sectionId + ": no non-conflicting slot available.");
            }
        }
        return new BlockScheduleResult(created, errors);
    }

    private double sumCurriculumUnits(int curriculumId, int yearLevel, int semester) {
        Double sum = db.queryForObject(
            "SELECT COALESCE(SUM(CASE " +
                "  WHEN c.is_coordinator_based = 1 AND c.coordinator_equivalent_units IS NOT NULL " +
                "    THEN c.coordinator_equivalent_units ELSE c.credit_units END), 0) " +
                "FROM curriculum_courses cc JOIN courses c ON c.course_id = cc.course_id " +
                "WHERE cc.curriculum_id = ? AND cc.year_level = ? AND cc.semester_number = ?",
            Double.class, curriculumId, yearLevel, semester);
        return sum != null ? sum : 0;
    }

    private int sectionTermId(int sectionId) {
        try {
            return db.queryForObject(
                "SELECT term_id FROM class_sections WHERE section_id = ?",
                Integer.class, sectionId);
        } catch (Exception e) {
            return -1;
        }
    }

    private Integer sectionFacultyId(int sectionId) {
        try {
            return db.queryForObject(
                "SELECT faculty_id FROM class_sections WHERE section_id = ?",
                Integer.class, sectionId);
        } catch (Exception e) {
            return null;
        }
    }

    private int countAutoFaculty(Integer departmentId) {
        if (departmentId == null) {
            return 0;
        }
        Integer count = db.queryForObject(
            "SELECT COUNT(*) FROM faculty WHERE department_id = ? AND employee_number LIKE 'AUTO-%'",
            Integer.class, departmentId);
        return count != null ? count : 0;
    }

    public record FacultyDistributionResult(int sectionsAssigned, int facultyProvisioned, List<String> notes) {}

    public record BlockScheduleResult(int slotsCreated, List<String> errors) {}
}
