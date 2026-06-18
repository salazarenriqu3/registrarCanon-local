package com.iuims.registrar.shift;

import com.iuims.registrar.forms.StudentDocumentTrailService;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.sql.PreparedStatement;
import java.sql.Statement;
import java.util.List;
import java.util.Map;

@Service
public class ProgramShiftRequestService {

    public static final String STATUS_PENDING_DEAN = "PENDING_DEAN";
    public static final String STATUS_PENDING_REGISTRAR = "PENDING_REGISTRAR";
    public static final String STATUS_APPROVED = "APPROVED";
    public static final String STATUS_REJECTED = "REJECTED";

    private final JdbcTemplate db;
    private final StudentDocumentTrailService documentTrailService;

    public ProgramShiftRequestService(JdbcTemplate db, StudentDocumentTrailService documentTrailService) {
        this.db = db;
        this.documentTrailService = documentTrailService;
    }

    public void ensureSchema() {
        db.execute("""
            CREATE TABLE IF NOT EXISTS student_program_shift_requests (
                request_id BIGINT AUTO_INCREMENT PRIMARY KEY,
                student_number VARCHAR(100) NOT NULL,
                from_program_code VARCHAR(20) NULL,
                to_program_code VARCHAR(20) NOT NULL,
                target_year_level INT NULL,
                target_semester INT NULL,
                target_curriculum_id INT NULL,
                reason VARCHAR(500) NULL,
                status VARCHAR(40) NOT NULL DEFAULT 'PENDING_DEAN',
                requested_by VARCHAR(100) NULL,
                requested_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                dean_approved_by VARCHAR(100) NULL,
                dean_approved_at TIMESTAMP NULL,
                registrar_approved_by VARCHAR(100) NULL,
                registrar_approved_at TIMESTAMP NULL,
                rejected_by VARCHAR(100) NULL,
                rejected_at TIMESTAMP NULL,
                rejection_reason VARCHAR(500) NULL,
                completed_at TIMESTAMP NULL
            )
            """);
        try {
            db.execute("CREATE INDEX idx_spsr_status ON student_program_shift_requests (status)");
        } catch (Exception ignored) {
        }
        try {
            db.execute("CREATE INDEX idx_spsr_student ON student_program_shift_requests (student_number)");
        } catch (Exception ignored) {
        }
    }

    public List<Map<String, Object>> listRequests(String status) {
        ensureSchema();
        String sql = baseRequestSql();
        if (status == null || status.isBlank()) {
            return db.queryForList(sql + "ORDER BY r.requested_at DESC, r.request_id DESC");
        }
        return db.queryForList(sql +
                "WHERE BINARY r.status = BINARY ? ORDER BY r.requested_at ASC, r.request_id ASC",
            status.trim().toUpperCase());
    }

    private String baseRequestSql() {
        return """
            SELECT r.request_id, r.student_number, COALESCE(s.real_name, r.student_number) AS student_name,
                   r.from_program_code, r.to_program_code, r.target_year_level, r.target_semester,
                   r.target_curriculum_id, ct.curriculum_name, r.reason, r.status,
                   r.requested_by, r.requested_at, r.dean_approved_by, r.dean_approved_at,
                   r.registrar_approved_by, r.registrar_approved_at, r.rejected_by,
                   r.rejected_at, r.rejection_reason, r.completed_at,
                   s.program_code AS current_program_code, s.year_level, s.semester
            FROM student_program_shift_requests r
            LEFT JOIN students s ON BINARY s.student_number = BINARY r.student_number
            LEFT JOIN curriculum_templates ct ON ct.curriculum_id = r.target_curriculum_id
            """;
    }

    @Transactional
    public long createRequest(String studentNumber,
                              String targetProgramCode,
                              Integer targetYearLevel,
                              Integer targetSemester,
                              Integer targetCurriculumId,
                              String reason,
                              String requestedBy) {
        ensureSchema();
        String sn = clean(studentNumber);
        String program = clean(targetProgramCode).toUpperCase();
        if (sn.isEmpty()) throw new IllegalArgumentException("Student number is required.");
        if (program.isEmpty()) throw new IllegalArgumentException("Target program is required.");
        ensureNoActiveRequest(sn);

        String fromProgram = null;
        try {
            fromProgram = db.queryForObject(
                "SELECT program_code FROM students WHERE student_number = ? LIMIT 1",
                String.class, sn);
        } catch (Exception ignored) {
        }
        final String capturedFromProgram = fromProgram;

        KeyHolder keyHolder = new GeneratedKeyHolder();
        db.update(connection -> {
            PreparedStatement ps = connection.prepareStatement(
                "INSERT INTO student_program_shift_requests " +
                    "(student_number, from_program_code, to_program_code, target_year_level, target_semester, " +
                    "target_curriculum_id, reason, status, requested_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                Statement.RETURN_GENERATED_KEYS);
            ps.setString(1, sn);
            ps.setString(2, capturedFromProgram);
            ps.setString(3, program);
            if (targetYearLevel != null) {
                ps.setInt(4, targetYearLevel);
            } else {
                ps.setObject(4, null);
            }
            if (targetSemester != null) {
                ps.setInt(5, targetSemester);
            } else {
                ps.setObject(5, null);
            }
            if (targetCurriculumId != null && targetCurriculumId > 0) {
                ps.setInt(6, targetCurriculumId);
            } else {
                ps.setObject(6, null);
            }
            ps.setString(7, truncate(reason, 500));
            ps.setString(8, STATUS_PENDING_DEAN);
            ps.setString(9, requestedBy);
            return ps;
        }, keyHolder);
        Number key = keyHolder.getKey();
        long requestId = key != null ? key.longValue() : db.queryForObject("SELECT LAST_INSERT_ID()", Long.class);

        documentTrailService.recordStudentEvent(
            sn,
            "STUDENT",
            "PROGRAM_SHIFT",
            "PROGRAM_SHIFT_REQUESTED",
            "Program shift request submitted",
            "From " + (fromProgram != null ? fromProgram : "N/A") + " to " + program +
                (reason != null && !reason.isBlank() ? ". " + truncate(reason, 500) : "") +
                ". Request #" + requestId + ".",
            requestedBy,
            requestId,
            "student_program_shift_requests",
            String.valueOf(requestId));
        return requestId;
    }

    private void ensureNoActiveRequest(String studentNumber) {
        Integer count = db.queryForObject(
            "SELECT COUNT(*) FROM student_program_shift_requests " +
                "WHERE BINARY student_number = BINARY ? " +
                "AND (BINARY status = BINARY ? OR BINARY status = BINARY ?)",
            Integer.class, studentNumber, STATUS_PENDING_DEAN, STATUS_PENDING_REGISTRAR);
        if (count != null && count > 0) {
            throw new IllegalArgumentException("This student already has a pending program shift request.");
        }
    }

    @Transactional
    public String deanApprove(long requestId, String approvedBy) {
        ensureSchema();
        int updated = db.update(
            "UPDATE student_program_shift_requests " +
                "SET status = ?, dean_approved_by = ?, dean_approved_at = CURRENT_TIMESTAMP " +
                "WHERE request_id = ? AND BINARY status = BINARY ?",
            STATUS_PENDING_REGISTRAR, clean(approvedBy), requestId, STATUS_PENDING_DEAN);
        if (updated == 0) return "Program shift request is no longer pending Dean approval.";
        recordTrailEvent(requestId, "PROGRAM_SHIFT_DEAN_APPROVED",
            "Program shift forwarded to Registrar", approvedBy);
        return "Program shift request forwarded to Registrar approval.";
    }

    @Transactional
    public Map<String, Object> prepareRegistrarApproval(long requestId, String approvedBy) {
        ensureSchema();
        List<Map<String, Object>> rows = db.queryForList(
            "SELECT * FROM student_program_shift_requests WHERE request_id = ?", requestId);
        if (rows.isEmpty()) throw new IllegalArgumentException("Program shift request not found.");
        Map<String, Object> row = rows.get(0);
        if (!STATUS_PENDING_REGISTRAR.equals(row.get("status"))) {
            throw new IllegalArgumentException("Program shift request is not pending Registrar approval.");
        }
        db.update(
            "UPDATE student_program_shift_requests " +
                "SET registrar_approved_by = ?, registrar_approved_at = CURRENT_TIMESTAMP " +
                "WHERE request_id = ? AND BINARY status = BINARY ?",
            clean(approvedBy), requestId, STATUS_PENDING_REGISTRAR);
        return row;
    }

    @Transactional
    public void markCompleted(long requestId) {
        ensureSchema();
        db.update(
            "UPDATE student_program_shift_requests SET status = ?, completed_at = CURRENT_TIMESTAMP " +
                "WHERE request_id = ?",
            STATUS_APPROVED, requestId);
        recordTrailEvent(requestId, "PROGRAM_SHIFT_COMPLETED",
            "Program shift completed", "registrar");
    }

    @Transactional
    public String reject(long requestId, String rejectedBy, String reason) {
        ensureSchema();
        int updated = db.update(
            "UPDATE student_program_shift_requests " +
                "SET status = ?, rejected_by = ?, rejected_at = CURRENT_TIMESTAMP, rejection_reason = ? " +
                "WHERE request_id = ? AND (BINARY status = BINARY ? OR BINARY status = BINARY ?)",
            STATUS_REJECTED, clean(rejectedBy), truncate(reason, 500), requestId,
            STATUS_PENDING_DEAN, STATUS_PENDING_REGISTRAR);
        if (updated == 0) return "Program shift request is no longer pending.";
        recordTrailEvent(requestId, "PROGRAM_SHIFT_REJECTED",
            reason != null && !reason.isBlank()
                ? "Program shift rejected: " + truncate(reason, 500)
                : "Program shift rejected",
            rejectedBy);
        return "Program shift request rejected.";
    }

    public Map<String, Long> statusCounts() {
        ensureSchema();
        Map<String, Long> counts = new java.util.LinkedHashMap<>();
        counts.put(STATUS_PENDING_DEAN, 0L);
        counts.put(STATUS_PENDING_REGISTRAR, 0L);
        counts.put(STATUS_APPROVED, 0L);
        counts.put(STATUS_REJECTED, 0L);
        for (Map<String, Object> row : db.queryForList(
                "SELECT status, COUNT(*) AS cnt FROM student_program_shift_requests GROUP BY status")) {
            counts.put(String.valueOf(row.get("status")), ((Number) row.get("cnt")).longValue());
        }
        return counts;
    }

    private void recordTrailEvent(long requestId, String eventType, String detail, String actor) {
        try {
            Map<String, Object> row = db.queryForMap(
                "SELECT student_number FROM student_program_shift_requests WHERE request_id = ? LIMIT 1",
                requestId);
            documentTrailService.recordStudentEvent(
                String.valueOf(row.get("student_number")),
                "STUDENT",
                "PROGRAM_SHIFT",
                eventType,
                detail,
                detail + " Request #" + requestId + ".",
                clean(actor),
                requestId,
                "student_program_shift_requests",
                String.valueOf(requestId));
        } catch (Exception ignored) {
        }
    }

    private String clean(String value) {
        return value != null ? value.trim() : "";
    }

    private String truncate(String value, int max) {
        if (value == null) return null;
        String trimmed = value.trim();
        return trimmed.length() <= max ? trimmed : trimmed.substring(0, max);
    }
}
