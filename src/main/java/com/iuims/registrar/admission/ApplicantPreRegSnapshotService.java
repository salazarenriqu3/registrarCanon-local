package com.iuims.registrar.admission;

import com.iuims.registrar.core.GlobalTermService;
import com.iuims.registrar.finance.TermFeeAdminService;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.text.DecimalFormat;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class ApplicantPreRegSnapshotService {

    private static final String SNAPSHOT_SOURCE = "REGISTRAR";

    private final JdbcTemplate db;
    private final TermFeeAdminService termFeeAdminService;
    private final GlobalTermService globalTermService;
    private final DecimalFormat moneyFormat = new DecimalFormat("#,##0.00");

    public ApplicantPreRegSnapshotService(JdbcTemplate db,
                                          TermFeeAdminService termFeeAdminService,
                                          GlobalTermService globalTermService) {
        this.db = db;
        this.termFeeAdminService = termFeeAdminService;
        this.globalTermService = globalTermService;
    }

    public void ensureSchema() {
        db.execute(
            "CREATE TABLE IF NOT EXISTS applicant_pre_reg_snapshots (" +
                " snapshot_id BIGINT AUTO_INCREMENT PRIMARY KEY," +
                " applicant_id BIGINT NULL," +
                " reference_number VARCHAR(50) NOT NULL," +
                " program_code VARCHAR(50) NOT NULL," +
                " program_name VARCHAR(150) NULL," +
                " year_level INT NULL," +
                " semester_number INT NULL," +
                " enrollment_type VARCHAR(30) NOT NULL DEFAULT 'IRREGULAR'," +
                " snapshot_source VARCHAR(30) NOT NULL DEFAULT 'REGISTRAR'," +
                " snapshot_status VARCHAR(20) NOT NULL DEFAULT 'DRAFT'," +
                " total_units DECIMAL(10,2) NOT NULL DEFAULT 0.00," +
                " tuition_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00," +
                " misc_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00," +
                " assessment_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00," +
                " notes TEXT NULL," +
                " evaluation_finalized_at DATETIME NULL," +
                " created_by VARCHAR(64) NULL," +
                " updated_by VARCHAR(64) NULL," +
                " finalized_by VARCHAR(64) NULL," +
                " created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP," +
                " updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP," +
                " UNIQUE KEY uq_pre_reg_snapshot_ref_source (reference_number, snapshot_source)," +
                " KEY idx_pre_reg_snapshot_applicant (applicant_id)," +
                " KEY idx_pre_reg_snapshot_program (program_code)" +
            ")"
        );
        db.execute(
            "CREATE TABLE IF NOT EXISTS applicant_pre_reg_subject_lines (" +
                " line_id BIGINT AUTO_INCREMENT PRIMARY KEY," +
                " snapshot_id BIGINT NOT NULL," +
                " reference_number VARCHAR(50) NOT NULL," +
                " course_id INT NULL," +
                " course_code VARCHAR(50) NOT NULL," +
                " course_title VARCHAR(255) NOT NULL," +
                " units DECIMAL(10,2) NOT NULL DEFAULT 0.00," +
                " year_level INT NULL," +
                " semester_number INT NULL," +
                " section_id INT NULL," +
                " section_code VARCHAR(50) NULL," +
                " schedule_text VARCHAR(500) NULL," +
                " tuition_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00," +
                " sort_order INT NOT NULL DEFAULT 0," +
                " created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP," +
                " KEY idx_pre_reg_lines_snapshot (snapshot_id)," +
                " KEY idx_pre_reg_lines_reference (reference_number)," +
                " KEY idx_pre_reg_lines_section (section_id)," +
                " CONSTRAINT fk_pre_reg_lines_snapshot FOREIGN KEY (snapshot_id) " +
                "   REFERENCES applicant_pre_reg_snapshots(snapshot_id) ON DELETE CASCADE" +
            ")"
        );
        ensureLineColumn("section_id", "INT NULL");
        ensureLineColumn("schedule_text", "VARCHAR(500) NULL");
        ensureLineColumn("tuition_amount", "DECIMAL(12,2) NOT NULL DEFAULT 0.00");
    }

    public boolean isIrregularApplicant(Map<String, Object> applicant) {
        if (applicant == null) {
            return false;
        }
        if (hasText(applicant.get("last_school")) || hasText(applicant.get("course_taken"))) {
            return true;
        }
        if (hasText(applicant.get("admission_classification"))) {
            String value = applicant.get("admission_classification").toString().toLowerCase();
            if (value.contains("transf") || value.contains("irreg")) {
                return true;
            }
        }
        Object yearLevel = applicant.get("year_level");
        return yearLevel instanceof Number && ((Number) yearLevel).intValue() >= 2;
    }

    public Map<String, Object> buildWorkspace(Map<String, Object> applicant) {
        ensureSchema();

        String refNo = asText(applicant != null ? applicant.get("reference_number") : null);
        Map<String, Object> workspace = new LinkedHashMap<>();
        Map<String, Object> snapshot = findSnapshotHeader(refNo);
        if (snapshot != null) {
            refreshSnapshotTotals(refNo);
            snapshot = findSnapshotHeader(refNo);
        }
        if (snapshot == null) {
            snapshot = new LinkedHashMap<>();
            snapshot.put("reference_number", refNo);
            snapshot.put("program_code", asText(applicant != null ? applicant.get("program1") : null));
            snapshot.put("program_name", resolveProgramName(asText(applicant != null ? applicant.get("program1") : null)));
            snapshot.put("year_level", applicant != null ? applicant.get("year_level") : null);
            snapshot.put("semester_number", applicant != null ? applicant.get("semester") : null);
            snapshot.put("snapshot_status", "DRAFT");
            snapshot.put("snapshot_source", SNAPSHOT_SOURCE);
            snapshot.put("tuition_amount", 0.0);
            snapshot.put("misc_amount", 0.0);
            snapshot.put("assessment_amount", 0.0);
            snapshot.put("total_units", 0.0);
            snapshot.put("notes", "");
        }

        List<Map<String, Object>> lines = listSnapshotLines(refNo);
        String programCode = asText(snapshot.get("program_code"));
        boolean finalized = isFinalized(snapshot);

        workspace.put("snapshot", snapshot);
        workspace.put("lines", lines);
        workspace.put("lineCount", lines.size());
        workspace.put("finalized", finalized);
        workspace.put("ready", finalized && lines.size() > 0);
        workspace.put("courseOptions", hasText(programCode) ? listProgramCurriculumCourses(programCode) : List.of());
        workspace.put("sectionOptions", hasText(programCode) ? listProgramCurrentSections(programCode) : List.of());
        return workspace;
    }

    public Map<String, Object> findSnapshotByReference(String refNo) {
        ensureSchema();
        Map<String, Object> header = findSnapshotHeader(refNo);
        if (header != null) {
            refreshSnapshotTotals(refNo);
            header = findSnapshotHeader(refNo);
        }
        List<Map<String, Object>> lines = listSnapshotLines(refNo);
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("exists", header != null);
        out.put("reference_number", refNo);
        out.put("snapshot", header);
        out.put("subject_lines", lines);
        out.put("line_count", lines.size());
        boolean finalized = header != null && isFinalized(header);
        out.put("finalized", finalized);
        out.put("ready", finalized && lines.size() > 0);
        return out;
    }

    public String upsertSnapshotHeader(String refNo,
                                       String programCode,
                                       Integer yearLevel,
                                       Integer semesterNumber,
                                       Double tuitionAmount,
                                       Double miscAmount,
                                       Double assessmentAmount,
                                       String notes,
                                       String actor) {
        ensureSchema();
        if (!hasText(refNo)) {
            return "Applicant reference number is required.";
        }
        if (!hasText(programCode)) {
            return "Program code is required before building an irregular pre-registration snapshot.";
        }

        Long snapshotId = findSnapshotId(refNo);
        Long applicantId = findApplicantId(refNo);
        String normalizedActor = hasText(actor) ? actor.trim() : "registrar";
        String programName = resolveProgramName(programCode);
        double tuition = tuitionAmount != null ? tuitionAmount : 0.0;
        double misc = miscAmount != null ? miscAmount : 0.0;
        double assessment = assessmentAmount != null ? assessmentAmount : 0.0;

        if (snapshotId == null) {
            db.update(
                "INSERT INTO applicant_pre_reg_snapshots (" +
                    "applicant_id, reference_number, program_code, program_name, year_level, semester_number, " +
                    "enrollment_type, snapshot_source, snapshot_status, tuition_amount, misc_amount, assessment_amount, " +
                    "notes, created_by, updated_by) " +
                "VALUES (?, ?, ?, ?, ?, ?, 'IRREGULAR', ?, 'DRAFT', ?, ?, ?, ?, ?, ?)",
                applicantId, refNo.trim(), programCode.trim(), programName, yearLevel, semesterNumber,
                SNAPSHOT_SOURCE, tuition, misc, assessment, trimToNull(notes), normalizedActor, normalizedActor
            );
        } else {
            if (isFinalized(snapshotId)) {
                return "Reopen the finalized irregular pre-registration snapshot before editing.";
            }
            db.update(
                "UPDATE applicant_pre_reg_snapshots SET " +
                    "applicant_id = ?, program_code = ?, program_name = ?, year_level = ?, semester_number = ?, " +
                    "tuition_amount = ?, misc_amount = ?, assessment_amount = ?, notes = ?, updated_by = ?, " +
                    "snapshot_source = ?, updated_at = NOW() " +
                "WHERE snapshot_id = ?",
                applicantId, programCode.trim(), programName, yearLevel, semesterNumber,
                tuition, misc, assessment, trimToNull(notes), normalizedActor, SNAPSHOT_SOURCE, snapshotId
            );
        }

        refreshSnapshotTotals(refNo);
        return "Irregular pre-registration header saved.";
    }

    public String addSubjectLine(String refNo, Integer courseId, Integer sectionId, String sectionCode) {
        ensureSchema();
        if (!hasText(refNo)) {
            return "Applicant reference number is required.";
        }
        if ((courseId == null || courseId <= 0) && (sectionId == null || sectionId <= 0)) {
            return "Choose a curriculum subject first.";
        }

        Map<String, Object> header = findSnapshotHeader(refNo);
        if (header == null) {
            return "Save the irregular pre-registration header first.";
        }
        if (isFinalized(header)) {
            return "Reopen the finalized irregular pre-registration snapshot before editing subjects.";
        }

        String programCode = asText(header.get("program_code"));
        if (!hasText(programCode)) {
            return "Snapshot program code is missing.";
        }

        Map<String, Object> selectedSection = sectionId != null && sectionId > 0 ? findSectionForProgram(programCode, sectionId) : null;
        if (sectionId != null && sectionId > 0 && selectedSection == null) {
            return "Selected section is not available for the active curriculum and current term.";
        }
        if (selectedSection != null) {
            courseId = ((Number) selectedSection.get("course_id")).intValue();
            sectionCode = asText(selectedSection.get("section_code"));
        }

        List<Map<String, Object>> rows = db.queryForList(
            "SELECT c.course_id, c.course_code, c.course_title, c.credit_units, cc.year_level, cc.semester_number " +
                "FROM curriculum_courses cc " +
                "JOIN curriculum_templates ct ON cc.curriculum_id = ct.curriculum_id " +
                "JOIN programs p ON ct.program_id = p.program_id " +
                "JOIN courses c ON c.course_id = cc.course_id " +
                "WHERE p.program_code = ? AND COALESCE(ct.is_active, 0) = 1 AND c.course_id = ? " +
                "ORDER BY cc.year_level, cc.semester_number, c.course_code LIMIT 1",
            programCode, courseId
        );
        if (rows.isEmpty()) {
            return "Selected course is not part of the active curriculum for " + programCode + ".";
        }

        Map<String, Object> course = rows.get(0);
        Long snapshotId = findSnapshotId(refNo);
        Integer dup = db.queryForObject(
            "SELECT COUNT(*) FROM applicant_pre_reg_subject_lines WHERE snapshot_id = ? AND course_id = ?",
            Integer.class, snapshotId, courseId
        );
        if (dup != null && dup > 0) {
            return "This course is already in the irregular pre-registration list.";
        }

        Integer nextSort = db.queryForObject(
            "SELECT COALESCE(MAX(sort_order), 0) + 1 FROM applicant_pre_reg_subject_lines WHERE snapshot_id = ?",
            Integer.class, snapshotId
        );

        db.update(
            "INSERT INTO applicant_pre_reg_subject_lines (" +
                "snapshot_id, reference_number, course_id, course_code, course_title, units, year_level, semester_number, " +
                "section_id, section_code, schedule_text, tuition_amount, sort_order) " +
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0.00, ?)",
            snapshotId, refNo.trim(),
            course.get("course_id"),
            course.get("course_code"),
            course.get("course_title"),
            course.get("credit_units"),
            course.get("year_level"),
            course.get("semester_number"),
            selectedSection != null ? selectedSection.get("section_id") : null,
            trimToNull(sectionCode),
            selectedSection != null ? trimToNull(asText(selectedSection.get("schedule_text"))) : null,
            nextSort != null ? nextSort : 1
        );

        refreshSnapshotTotals(refNo);
        return "Subject added to irregular pre-registration.";
    }

    public String removeSubjectLine(String refNo, Long lineId) {
        ensureSchema();
        if (lineId == null || lineId <= 0) {
            return "Subject line not found.";
        }
        Long snapshotId = findSnapshotId(refNo);
        if (snapshotId != null && isFinalized(snapshotId)) {
            return "Reopen the finalized irregular pre-registration snapshot before editing subjects.";
        }
        int deleted = db.update(
            "DELETE l FROM applicant_pre_reg_subject_lines l " +
                "JOIN applicant_pre_reg_snapshots s ON s.snapshot_id = l.snapshot_id " +
                "WHERE l.line_id = ? AND s.reference_number = ? AND s.snapshot_source = ?",
            lineId, refNo, SNAPSHOT_SOURCE
        );
        refreshSnapshotTotals(refNo);
        return deleted > 0 ? "Subject removed from irregular pre-registration." : "Subject line not found.";
    }

    public String finalizeSnapshot(String refNo, String actor) {
        ensureSchema();
        Long snapshotId = findSnapshotId(refNo);
        if (snapshotId == null) {
            return "Save the irregular pre-registration header first.";
        }
        Integer count = db.queryForObject(
            "SELECT COUNT(*) FROM applicant_pre_reg_subject_lines WHERE snapshot_id = ?",
            Integer.class, snapshotId
        );
        if (count == null || count <= 0) {
            return "At least one subject line is required before finalizing.";
        }
        refreshSnapshotTotals(refNo);
        db.update(
            "UPDATE applicant_pre_reg_snapshots SET snapshot_status = 'FINAL', snapshot_source = ?, " +
                "evaluation_finalized_at = NOW(), finalized_by = ?, updated_by = ?, updated_at = NOW() " +
                "WHERE snapshot_id = ?",
            SNAPSHOT_SOURCE, hasText(actor) ? actor.trim() : "registrar", hasText(actor) ? actor.trim() : "registrar", snapshotId
        );
        return "Irregular pre-registration finalized.";
    }

    public String reopenSnapshot(String refNo, String actor) {
        ensureSchema();
        Long snapshotId = findSnapshotId(refNo);
        if (snapshotId == null) {
            return "Snapshot not found.";
        }
        db.update(
            "UPDATE applicant_pre_reg_snapshots SET snapshot_status = 'DRAFT', evaluation_finalized_at = NULL, " +
                "updated_by = ?, updated_at = NOW() WHERE snapshot_id = ?",
            hasText(actor) ? actor.trim() : "registrar", snapshotId
        );
        return "Irregular pre-registration reopened for editing.";
    }

    public String validateIrregularAdmissionReady(String refNo, String targetProgramCode, int yearLevel) {
        ensureSchema();
        if (yearLevel < 2) {
            return null;
        }
        return validateRegistrarSnapshotReady(refNo, targetProgramCode);
    }

    public String validateRegistrarSnapshotReady(String refNo, String targetProgramCode) {
        ensureSchema();
        Map<String, Object> header = findSnapshotHeader(refNo);
        if (header == null) {
            return "Irregular applicant admission is blocked until Registrar saves a pre-registration snapshot.";
        }
        if (!isFinalized(header)) {
            return "Irregular applicant admission is blocked until Registrar finalizes the pre-registration snapshot.";
        }

        String snapshotProgramCode = asText(header.get("program_code"));
        if (hasText(targetProgramCode) && hasText(snapshotProgramCode)
                && !targetProgramCode.trim().equalsIgnoreCase(snapshotProgramCode.trim())) {
            return "Irregular applicant admission is blocked because the registrar snapshot program (" + snapshotProgramCode
                + ") does not match the selected program (" + targetProgramCode + ").";
        }

        Integer lineCount = db.queryForObject(
            "SELECT COUNT(*) FROM applicant_pre_reg_subject_lines WHERE snapshot_id = ?",
            Integer.class, header.get("snapshot_id")
        );
        if (lineCount == null || lineCount <= 0) {
            return "Irregular applicant admission is blocked until Registrar assigns subject lines.";
        }
        return null;
    }

    private void refreshSnapshotTotals(String refNo) {
        Long snapshotId = findSnapshotId(refNo);
        if (snapshotId == null) {
            return;
        }
        Double totalUnits = db.queryForObject(
            "SELECT COALESCE(SUM(units), 0) FROM applicant_pre_reg_subject_lines WHERE snapshot_id = ?",
            Double.class, snapshotId
        );
        double units = totalUnits != null ? totalUnits : 0.0;
        Map<String, Object> header = findSnapshotHeader(refNo);
        FeeEstimate fees = estimateOfficialFees(header, units);
        db.update(
            "UPDATE applicant_pre_reg_snapshots SET total_units = ?, tuition_amount = ?, misc_amount = ?, " +
                "assessment_amount = ?, updated_at = NOW() WHERE snapshot_id = ?",
            units, fees.tuition, fees.miscAndOther, fees.total, snapshotId
        );
        double rate = units > 0.0 ? fees.tuition / units : 0.0;
        db.update(
            "UPDATE applicant_pre_reg_subject_lines SET tuition_amount = ROUND(units * ?, 2) WHERE snapshot_id = ?",
            rate, snapshotId
        );
    }

    private Long findApplicantId(String refNo) {
        try {
            return db.queryForObject(
                "SELECT id FROM applicants WHERE reference_number = ? LIMIT 1",
                Long.class, refNo.trim()
            );
        } catch (Exception e) {
            return null;
        }
    }

    private Long findSnapshotId(String refNo) {
        try {
            return db.queryForObject(
                "SELECT snapshot_id FROM applicant_pre_reg_snapshots WHERE reference_number = ? AND snapshot_source = ? LIMIT 1",
                Long.class, refNo.trim(), SNAPSHOT_SOURCE
            );
        } catch (Exception e) {
            return null;
        }
    }

    private boolean isFinalized(Long snapshotId) {
        if (snapshotId == null) {
            return false;
        }
        try {
            Map<String, Object> header = db.queryForMap(
                "SELECT snapshot_status, evaluation_finalized_at FROM applicant_pre_reg_snapshots WHERE snapshot_id = ? LIMIT 1",
                snapshotId
            );
            return isFinalized(header);
        } catch (Exception e) {
            return false;
        }
    }

    private boolean isFinalized(Map<String, Object> header) {
        return header != null && (header.get("evaluation_finalized_at") != null
            || "FINAL".equalsIgnoreCase(asText(header.get("snapshot_status"))));
    }

    private Map<String, Object> findSnapshotHeader(String refNo) {
        if (!hasText(refNo)) {
            return null;
        }
        try {
            return db.queryForMap(
                "SELECT s.* FROM applicant_pre_reg_snapshots s " +
                    "WHERE s.reference_number = ? AND s.snapshot_source = ? LIMIT 1",
                refNo.trim(), SNAPSHOT_SOURCE
            );
        } catch (Exception e) {
            return null;
        }
    }

    private List<Map<String, Object>> listSnapshotLines(String refNo) {
        Long snapshotId = findSnapshotId(refNo);
        if (snapshotId == null) {
            return new ArrayList<>();
        }
        List<Map<String, Object>> lines = db.queryForList(
            "SELECT line_id, course_id, course_code, course_title, units, year_level, semester_number, " +
                "section_id, section_code, schedule_text, tuition_amount, sort_order " +
                "FROM applicant_pre_reg_subject_lines WHERE snapshot_id = ? ORDER BY sort_order, line_id",
            snapshotId
        );
        for (Map<String, Object> line : lines) {
            double tuition = line.get("tuition_amount") instanceof Number ? ((Number) line.get("tuition_amount")).doubleValue() : 0.0;
            line.put("tuition_amount_fmt", moneyFormat.format(tuition));
            if (!(line.get("section_id") instanceof Number) && hasText(line.get("section_code")) && line.get("course_id") instanceof Number) {
                Map<String, Object> resolved = findSectionByCourseAndCode(
                    ((Number) line.get("course_id")).intValue(),
                    asText(line.get("section_code"))
                );
                if (resolved != null) {
                    line.put("section_id", resolved.get("section_id"));
                    line.put("schedule_text", resolved.get("schedule_text"));
                    db.update(
                        "UPDATE applicant_pre_reg_subject_lines SET section_id = ?, schedule_text = ? WHERE line_id = ?",
                        resolved.get("section_id"), resolved.get("schedule_text"), line.get("line_id")
                    );
                }
            }
            if (!hasText(line.get("schedule_text")) && line.get("section_id") instanceof Number) {
                String schedule = resolveSectionSchedule(((Number) line.get("section_id")).intValue());
                line.put("schedule_text", schedule);
            }
        }
        return lines;
    }

    private List<Map<String, Object>> listProgramCurrentSections(String programCode) {
        Integer termId = globalTermService.getCurrentTermId();
        List<Map<String, Object>> rows = db.queryForList(
            "SELECT cs.section_id, cs.course_id, c.course_code, c.course_title, c.credit_units, " +
                "cc.year_level, cc.semester_number, cs.section_code, cs.max_capacity, " +
                scheduleSql("cs.section_id") + " AS schedule_text, " +
                "(SELECT COUNT(*) FROM student_enlistments se WHERE se.section_id = cs.section_id) AS enrolled_count " +
            "FROM class_sections cs " +
            "JOIN courses c ON c.course_id = cs.course_id " +
            "JOIN curriculum_courses cc ON cc.course_id = c.course_id " +
            "JOIN curriculum_templates ct ON ct.curriculum_id = cc.curriculum_id AND COALESCE(ct.is_active, 0) = 1 " +
            "JOIN programs p ON p.program_id = ct.program_id " +
            "WHERE p.program_code = ? " +
                (termId != null ? "AND cs.term_id = ? " : "") +
            "ORDER BY c.course_code, cs.section_code",
            termId != null ? new Object[]{programCode.trim(), termId} : new Object[]{programCode.trim()}
        );
        for (Map<String, Object> row : rows) {
            int max = row.get("max_capacity") instanceof Number ? ((Number) row.get("max_capacity")).intValue() : 0;
            int enrolled = row.get("enrolled_count") instanceof Number ? ((Number) row.get("enrolled_count")).intValue() : 0;
            row.put("slots_left", Math.max(0, max - enrolled));
            row.put("label", row.get("course_code") + " - " + row.get("course_title") +
                " | " + row.get("section_code") + " | " + row.get("schedule_text") +
                " | " + row.get("credit_units") + "u");
        }
        return rows;
    }

    private Map<String, Object> findSectionForProgram(String programCode, Integer sectionId) {
        Integer termId = globalTermService.getCurrentTermId();
        List<Map<String, Object>> rows = db.queryForList(
            "SELECT cs.section_id, cs.course_id, c.course_code, c.course_title, c.credit_units, " +
                "cc.year_level, cc.semester_number, cs.section_code, " +
                scheduleSql("cs.section_id") + " AS schedule_text " +
            "FROM class_sections cs " +
            "JOIN courses c ON c.course_id = cs.course_id " +
            "JOIN curriculum_courses cc ON cc.course_id = c.course_id " +
            "JOIN curriculum_templates ct ON ct.curriculum_id = cc.curriculum_id AND COALESCE(ct.is_active, 0) = 1 " +
            "JOIN programs p ON p.program_id = ct.program_id " +
            "WHERE p.program_code = ? AND cs.section_id = ? " +
                (termId != null ? "AND cs.term_id = ? " : "") +
            "LIMIT 1",
            termId != null ? new Object[]{programCode.trim(), sectionId, termId} : new Object[]{programCode.trim(), sectionId}
        );
        return rows.isEmpty() ? null : rows.get(0);
    }

    private Map<String, Object> findSectionByCourseAndCode(Integer courseId, String sectionCode) {
        if (courseId == null || !hasText(sectionCode)) {
            return null;
        }
        Integer termId = globalTermService.getCurrentTermId();
        List<Map<String, Object>> rows = db.queryForList(
            "SELECT cs.section_id, cs.section_code, " + scheduleSql("cs.section_id") + " AS schedule_text " +
                "FROM class_sections cs WHERE cs.course_id = ? AND UPPER(cs.section_code) = UPPER(?) " +
                (termId != null ? "AND cs.term_id = ? " : "") +
                "ORDER BY cs.section_id DESC LIMIT 1",
            termId != null ? new Object[]{courseId, sectionCode.trim(), termId} : new Object[]{courseId, sectionCode.trim()}
        );
        return rows.isEmpty() ? null : rows.get(0);
    }

    private String resolveSectionSchedule(Integer sectionId) {
        try {
            return db.queryForObject("SELECT " + scheduleSql("?"), String.class, sectionId);
        } catch (Exception e) {
            return "TBA";
        }
    }

    private String scheduleSql(String sectionExpression) {
        return "IFNULL((SELECT GROUP_CONCAT(" +
            "CONCAT(CASE sch.day_of_week WHEN 1 THEN 'MON' WHEN 2 THEN 'TUE' WHEN 3 THEN 'WED' " +
            "WHEN 4 THEN 'THU' WHEN 5 THEN 'FRI' WHEN 6 THEN 'SAT' ELSE 'SUN' END, " +
            "' ', TIME_FORMAT(sch.start_time,'%h:%i %p'), '-', TIME_FORMAT(sch.end_time,'%h:%i %p'), " +
            "' ', IFNULL(r.room_code,'TBA')) ORDER BY sch.day_of_week SEPARATOR ' | ') " +
            "FROM class_schedules sch LEFT JOIN rooms r ON r.room_id = sch.room_id " +
            "WHERE sch.section_id = " + sectionExpression + "), 'TBA')";
    }

    private List<Map<String, Object>> listProgramCurriculumCourses(String programCode) {
        return db.queryForList(
            "SELECT c.course_id, c.course_code, c.course_title, c.credit_units, cc.year_level, cc.semester_number " +
                "FROM curriculum_courses cc " +
                "JOIN curriculum_templates ct ON cc.curriculum_id = ct.curriculum_id " +
                "JOIN programs p ON ct.program_id = p.program_id " +
                "JOIN courses c ON c.course_id = cc.course_id " +
                "WHERE p.program_code = ? AND COALESCE(ct.is_active, 0) = 1 " +
                "ORDER BY cc.year_level, cc.semester_number, c.course_code",
            programCode.trim()
        );
    }

    private String resolveProgramName(String programCode) {
        if (!hasText(programCode)) {
            return null;
        }
        try {
            return db.queryForObject(
                "SELECT program_name FROM programs WHERE program_code = ? LIMIT 1",
                String.class, programCode.trim()
            );
        } catch (Exception e) {
            return null;
        }
    }

    private FeeEstimate estimateOfficialFees(Map<String, Object> header, double units) {
        if (header == null || units <= 0.0) {
            return new FeeEstimate(0.0, 0.0);
        }
        String programCode = asText(header.get("program_code"));
        int yearLevel = header.get("year_level") instanceof Number ? ((Number) header.get("year_level")).intValue() : 1;
        int semester = header.get("semester_number") instanceof Number
            ? ((Number) header.get("semester_number")).intValue()
            : (globalTermService.getCurrentSemesterNumber() != null ? globalTermService.getCurrentSemesterNumber() : 1);
        try {
            Integer programId = termFeeAdminService.resolveProgramId(programCode);
            Map<String, Double> rates = programId != null
                ? termFeeAdminService.getFeeRatesForScope(programId, globalTermService.getCurrentTermId(), yearLevel, semester)
                : Map.of();
            double tuitionRate = rates.getOrDefault("TUITION_PER_UNIT", 0.0);
            double tuition = units * tuitionRate;
            double miscAndOther = 0.0;
            for (Map.Entry<String, Double> entry : rates.entrySet()) {
                String code = entry.getKey() != null ? entry.getKey().toUpperCase() : "";
                if (code.startsWith("MISC_") || code.startsWith("OTHER_")) {
                    miscAndOther += entry.getValue() != null ? entry.getValue() : 0.0;
                }
            }
            return new FeeEstimate(tuition, miscAndOther);
        } catch (Exception e) {
            double tuition = header.get("tuition_amount") instanceof Number ? ((Number) header.get("tuition_amount")).doubleValue() : 0.0;
            double misc = header.get("misc_amount") instanceof Number ? ((Number) header.get("misc_amount")).doubleValue() : 0.0;
            double assessment = header.get("assessment_amount") instanceof Number ? ((Number) header.get("assessment_amount")).doubleValue() : tuition + misc;
            return new FeeEstimate(tuition, Math.max(0.0, assessment - tuition));
        }
    }

    private void ensureLineColumn(String columnName, String definition) {
        try {
            Integer exists = db.queryForObject(
                "SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS " +
                    "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'applicant_pre_reg_subject_lines' AND COLUMN_NAME = ?",
                Integer.class, columnName
            );
            if (exists == null || exists == 0) {
                db.execute("ALTER TABLE applicant_pre_reg_subject_lines ADD COLUMN " + columnName + " " + definition);
            }
        } catch (Exception ignored) {
        }
    }

    private static final class FeeEstimate {
        final double tuition;
        final double miscAndOther;
        final double total;

        FeeEstimate(double tuition, double miscAndOther) {
            this.tuition = Math.max(0.0, tuition);
            this.miscAndOther = Math.max(0.0, miscAndOther);
            this.total = this.tuition + this.miscAndOther;
        }
    }

    private boolean hasText(Object value) {
        return value != null && !value.toString().trim().isEmpty();
    }

    private String asText(Object value) {
        return value != null ? value.toString() : "";
    }

    private String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
