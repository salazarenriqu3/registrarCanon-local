package com.iuims.registrar.faculty;

import com.iuims.registrar.academic.SchedulingPolicyConstants;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

/**
 * Ensures faculty teaching defaults and provisions additional faculty when load planning needs capacity.
 */
@Service
public class FacultyProvisioningService {

    private final JdbcTemplate db;

    public FacultyProvisioningService(JdbcTemplate db) {
        this.db = db;
    }

    public void ensureFacultyTeachingDefaults() {
        db.update(
            "UPDATE faculty SET max_teaching_units = ? " +
                "WHERE max_teaching_units IS NULL OR max_teaching_units <= 0",
            SchedulingPolicyConstants.DEFAULT_FACULTY_MAX_TEACHING_UNITS);
    }

    /**
     * Returns a faculty_id with at least {@code requiredUnits} remaining capacity in the term,
     * creating a placeholder faculty row in the department when none are available.
     */
    @Transactional
    public int findOrProvisionFacultyWithCapacity(Integer departmentId, int termId, double requiredUnits) {
        ensureFacultyTeachingDefaults();
        int deptId = departmentId != null && departmentId > 0 ? departmentId : resolveFallbackDepartmentId();
        Integer existing = findFacultyWithRemainingCapacity(deptId, termId, requiredUnits);
        if (existing != null) {
            return existing;
        }
        return createPlaceholderFaculty(deptId);
    }

    public Integer findFacultyWithRemainingCapacity(int departmentId, int termId, double requiredUnits) {
        ensureFacultyTeachingDefaults();
        List<Map<String, Object>> rows = db.queryForList(
            "SELECT f.faculty_id, f.max_teaching_units, " +
                "COALESCE(SUM(CASE " +
                "  WHEN c.is_coordinator_based = 1 AND c.coordinator_equivalent_units IS NOT NULL " +
                "    THEN c.coordinator_equivalent_units ELSE c.credit_units END), 0) AS load_units " +
                "FROM faculty f " +
                "LEFT JOIN class_sections cs ON cs.faculty_id = f.faculty_id AND cs.term_id = ? " +
                "LEFT JOIN courses c ON c.course_id = cs.course_id " +
                "WHERE f.department_id = ? AND COALESCE(f.active_status, 1) = 1 " +
                "GROUP BY f.faculty_id, f.max_teaching_units " +
                "HAVING (f.max_teaching_units - load_units) >= ? " +
                "ORDER BY load_units ASC, f.faculty_id ASC LIMIT 1",
            termId, departmentId, requiredUnits);
        if (rows.isEmpty()) {
            return null;
        }
        return ((Number) rows.get(0).get("faculty_id")).intValue();
    }

    public Integer resolveProgramDepartmentId(String programCode) {
        if (programCode == null || programCode.isBlank()) {
            return resolveFallbackDepartmentId();
        }
        try {
            return db.queryForObject(
                "SELECT p.department_id FROM programs p WHERE p.program_code = ? LIMIT 1",
                Integer.class, programCode.trim().toUpperCase());
        } catch (Exception e) {
            return resolveFallbackDepartmentId();
        }
    }

    private int resolveFallbackDepartmentId() {
        try {
            return db.queryForObject(
                "SELECT department_id FROM departments ORDER BY department_id LIMIT 1",
                Integer.class);
        } catch (Exception e) {
            db.update(
                "INSERT INTO departments (department_code, department_name, active_status) " +
                    "VALUES ('GEN', 'General Academic Affairs', 1)");
            return db.queryForObject("SELECT LAST_INSERT_ID()", Integer.class);
        }
    }

    private int createPlaceholderFaculty(int departmentId) {
        ensureFacultyTeachingDefaults();
        String deptCode;
        try {
            deptCode = db.queryForObject(
                "SELECT department_code FROM departments WHERE department_id = ?",
                String.class, departmentId);
        } catch (Exception e) {
            deptCode = "GEN";
        }
        int seq = nextFacultySequence(departmentId);
        String employeeNumber = "AUTO-" + deptCode + "-" + seq;
        String firstName = "Auto";
        String lastName = "Faculty " + deptCode + "-" + seq;
        db.update(
            "INSERT INTO faculty (employee_number, first_name, last_name, department_id, employment_type, " +
                "max_teaching_units, active_status) VALUES (?, ?, ?, ?, 'Part-Time', ?, 1)",
            employeeNumber, firstName, lastName, departmentId,
            SchedulingPolicyConstants.DEFAULT_FACULTY_MAX_TEACHING_UNITS);
        return db.queryForObject("SELECT LAST_INSERT_ID()", Integer.class);
    }

    private int nextFacultySequence(int departmentId) {
        Integer count = db.queryForObject(
            "SELECT COUNT(*) FROM faculty WHERE department_id = ? AND employee_number LIKE 'AUTO-%'",
            Integer.class, departmentId);
        return (count != null ? count : 0) + 1;
    }
}
