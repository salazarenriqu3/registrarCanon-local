package com.iuims.registrar.withdrawal;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.iuims.registrar.core.EnlistmentSchemaService;
import com.iuims.registrar.core.EnrollmentPeriodPolicy;
import com.iuims.registrar.core.GlobalTermService;
import com.iuims.registrar.forms.RegFormEventService;
import com.iuims.registrar.forms.StudentDocumentTrailService;
import com.iuims.registrar.scholarship.ScholarEnrollmentService;

import java.sql.PreparedStatement;
import java.sql.Statement;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Service
public class WithdrawalService {

    public static final String STATUS_PENDING_DEAN = "PENDING_DEAN";
    public static final String STATUS_PENDING_REGISTRAR = "PENDING_REGISTRAR";
    public static final String STATUS_APPROVED = "APPROVED";
    public static final String STATUS_REJECTED = "REJECTED";
    public static final String STATUS_SUPERSEDED = "SUPERSEDED";

    private final JdbcTemplate db;
    private final ScholarEnrollmentService scholarEnrollmentService;
    private final StudentDocumentTrailService documentTrailService;
    private final RegFormEventService regFormEventService;
    private final GlobalTermService globalTermService;
    private final EnlistmentSchemaService enlistmentSchemaService;

    public WithdrawalService(JdbcTemplate db, ScholarEnrollmentService scholarEnrollmentService,
                             StudentDocumentTrailService documentTrailService,
                             RegFormEventService regFormEventService,
                             GlobalTermService globalTermService,
                             EnlistmentSchemaService enlistmentSchemaService) {
        this.db = db;
        this.scholarEnrollmentService = scholarEnrollmentService;
        this.documentTrailService = documentTrailService;
        this.regFormEventService = regFormEventService;
        this.globalTermService = globalTermService;
        this.enlistmentSchemaService = enlistmentSchemaService;
    }

    public void ensureSchema() {
        db.execute("""
            CREATE TABLE IF NOT EXISTS withdrawal_reasons (
                reason_code VARCHAR(40) PRIMARY KEY,
                reason_label VARCHAR(160) NOT NULL,
                is_active TINYINT(1) NOT NULL DEFAULT 1,
                sort_order INT NOT NULL DEFAULT 100
            )
            """);
        db.execute("""
            CREATE TABLE IF NOT EXISTS student_withdrawal_requests (
                request_id BIGINT AUTO_INCREMENT PRIMARY KEY,
                student_number VARCHAR(100) NOT NULL,
                section_id INT NOT NULL,
                course_id INT NOT NULL,
                term_id INT NULL,
                reason_code VARCHAR(40) NOT NULL,
                remarks VARCHAR(500) NULL,
                requested_on DATE NULL,
                enlisted_at TIMESTAMP NULL,
                days_enrolled_at_request INT NULL,
                timing_bucket VARCHAR(40) NULL,
                charge_percent DECIMAL(5,2) NOT NULL DEFAULT 0,
                estimated_charge DECIMAL(12,2) NOT NULL DEFAULT 0,
                deadline_blocked TINYINT(1) NOT NULL DEFAULT 0,
                policy_note VARCHAR(255) NULL,
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
                completed_at TIMESTAMP NULL,
                CONSTRAINT fk_swr_reason FOREIGN KEY (reason_code) REFERENCES withdrawal_reasons(reason_code)
            )
            """);
        addColumnIfMissing("student_withdrawal_requests", "requested_on", "DATE NULL");
        addColumnIfMissing("student_withdrawal_requests", "enlisted_at", "TIMESTAMP NULL");
        addColumnIfMissing("student_withdrawal_requests", "days_enrolled_at_request", "INT NULL");
        addColumnIfMissing("student_withdrawal_requests", "timing_bucket", "VARCHAR(40) NULL");
        addColumnIfMissing("student_withdrawal_requests", "charge_percent", "DECIMAL(5,2) NOT NULL DEFAULT 0");
        addColumnIfMissing("student_withdrawal_requests", "estimated_charge", "DECIMAL(12,2) NOT NULL DEFAULT 0");
        addColumnIfMissing("student_withdrawal_requests", "deadline_blocked", "TINYINT(1) NOT NULL DEFAULT 0");
        addColumnIfMissing("student_withdrawal_requests", "policy_note", "VARCHAR(255) NULL");
        addColumnIfMissing("student_withdrawal_requests", "withdrawal_scope", "VARCHAR(30) NOT NULL DEFAULT 'SINGLE_SUBJECT'");
        addColumnIfMissing("student_withdrawal_requests", "subject_count", "INT NOT NULL DEFAULT 1");
        addColumnIfMissing("student_withdrawal_requests", "approval_source", "VARCHAR(40) NULL");
        addColumnIfMissing("academic_term_policies", "midterm_exam_date", "DATE NULL");
        db.execute("""
            CREATE TABLE IF NOT EXISTS student_withdrawal_request_lines (
                line_id BIGINT AUTO_INCREMENT PRIMARY KEY,
                request_id BIGINT NOT NULL,
                student_number VARCHAR(100) NOT NULL,
                section_id INT NOT NULL,
                course_id INT NOT NULL,
                status VARCHAR(40) NOT NULL DEFAULT 'PENDING_DEAN',
                completed_at TIMESTAMP NULL,
                CONSTRAINT fk_swrl_request FOREIGN KEY (request_id) REFERENCES student_withdrawal_requests(request_id)
            )
            """);
        try {
            db.execute("CREATE INDEX idx_swr_status ON student_withdrawal_requests (status)");
        } catch (Exception ignored) {
        }
        try {
            db.execute("CREATE INDEX idx_swr_student ON student_withdrawal_requests (student_number)");
        } catch (Exception ignored) {
        }
        try {
            db.execute("CREATE INDEX idx_swr_section ON student_withdrawal_requests (student_number, section_id, status)");
        } catch (Exception ignored) {
        }
        seedDefaultReasons();
    }

    private void addColumnIfMissing(String tableName, String columnName, String definition) {
        try {
            Integer count = db.queryForObject(
                "SELECT COUNT(*) FROM information_schema.columns " +
                    "WHERE table_schema = DATABASE() AND table_name = ? AND column_name = ?",
                Integer.class, tableName, columnName);
            if (count == null || count == 0) {
                db.execute("ALTER TABLE " + tableName + " ADD COLUMN " + columnName + " " + definition);
            }
        } catch (Exception ignored) {
        }
    }

    private void seedDefaultReasons() {
        db.update("""
            INSERT IGNORE INTO withdrawal_reasons (reason_code, reason_label, sort_order) VALUES
            ('ACADEMIC_LOAD', 'Academic load adjustment', 10),
            ('SCHEDULE_CONFLICT', 'Schedule conflict', 20),
            ('MEDICAL', 'Medical / health reason', 30),
            ('FINANCIAL', 'Financial reason', 40),
            ('TRANSFER', 'Transfer / change of school', 50),
            ('OTHER', 'Other reason', 100)
            """);
    }

    public List<Map<String, Object>> listActiveReasons() {
        ensureSchema();
        return db.queryForList(
            "SELECT reason_code, reason_label FROM withdrawal_reasons " +
                "WHERE COALESCE(is_active, 1) = 1 ORDER BY sort_order, reason_label");
    }

    public List<Map<String, Object>> listStudentRequests(String studentNumber) {
        if (studentNumber == null || studentNumber.isBlank()) return List.of();
        ensureSchema();
        return db.queryForList(baseRequestSql() +
                "WHERE BINARY wr.student_number = BINARY ? ORDER BY wr.requested_at DESC, wr.request_id DESC",
            studentNumber.trim());
    }

    public List<Map<String, Object>> listRequests(String status) {
        ensureSchema();
        if (status == null || status.isBlank()) {
            return db.queryForList(baseRequestSql() + "ORDER BY wr.requested_at DESC, wr.request_id DESC");
        }
        return db.queryForList(baseRequestSql() +
                "WHERE BINARY wr.status = BINARY ? ORDER BY wr.requested_at ASC, wr.request_id ASC",
            status.trim().toUpperCase());
    }

    private String baseRequestSql() {
        return """
            SELECT wr.request_id, wr.student_number, COALESCE(s.real_name, wr.student_number) AS student_name,
                   s.program_code, s.year_level, wr.section_id, wr.course_id, wr.term_id,
                   c.course_code, c.course_title, c.credit_units, cs.section_code,
                   wr.reason_code, rr.reason_label, wr.remarks, wr.status,
                   wr.withdrawal_scope, wr.subject_count, wr.approval_source,
                   wr.requested_on, wr.enlisted_at, wr.days_enrolled_at_request,
                   wr.timing_bucket, wr.charge_percent, wr.estimated_charge,
                   wr.deadline_blocked, wr.policy_note,
                   wr.requested_by, wr.requested_at, wr.dean_approved_by, wr.dean_approved_at,
                   wr.registrar_approved_by, wr.registrar_approved_at, wr.rejected_by,
                   wr.rejected_at, wr.rejection_reason, wr.completed_at
            FROM student_withdrawal_requests wr
            LEFT JOIN students s ON BINARY s.student_number = BINARY wr.student_number
            LEFT JOIN courses c ON c.course_id = wr.course_id
            LEFT JOIN class_sections cs ON cs.section_id = wr.section_id
            LEFT JOIN withdrawal_reasons rr ON BINARY rr.reason_code = BINARY wr.reason_code
            """;
    }

    @Transactional
    public long createRequest(String studentNumber, Integer sectionId, String reasonCode, String remarks, String requestedBy) {
        ensureSchema();
        String sn = clean(studentNumber);
        String rc = clean(reasonCode).toUpperCase();
        if (sn.isEmpty()) throw new IllegalArgumentException("Student number is required.");
        if (sectionId == null || sectionId <= 0) throw new IllegalArgumentException("Subject section is required.");
        if (rc.isEmpty()) throw new IllegalArgumentException("Withdrawal reason is required.");
        ensureReasonExists(rc);

        String withdrawalBlock = EnrollmentPeriodPolicy.withdrawalBlockMessage(db);
        if (withdrawalBlock != null) {
            throw new IllegalArgumentException(withdrawalBlock);
        }

        Map<String, Object> enlistment = findActiveEnlistment(sn, sectionId);
        int courseId = ((Number) enlistment.get("course_id")).intValue();
        Integer termId = enlistment.get("term_id") instanceof Number n ? n.intValue() : null;
        WithdrawalPolicySnapshot policy = computePolicySnapshot(sn, enlistment);
        if (policy.deadlineBlocked()) {
            throw new IllegalArgumentException(policy.policyNote());
        }
        ensureNoActiveRequest(sn, sectionId);

        KeyHolder keyHolder = new GeneratedKeyHolder();
        db.update(connection -> {
            PreparedStatement ps = connection.prepareStatement(
                "INSERT INTO student_withdrawal_requests " +
                    "(student_number, section_id, course_id, term_id, reason_code, remarks, requested_on, " +
                    "enlisted_at, days_enrolled_at_request, timing_bucket, charge_percent, estimated_charge, " +
                    "deadline_blocked, policy_note, status, requested_by) " +
                    "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                Statement.RETURN_GENERATED_KEYS);
            ps.setString(1, sn);
            ps.setInt(2, sectionId);
            ps.setInt(3, courseId);
            if (termId != null) {
                ps.setInt(4, termId);
            } else {
                ps.setObject(4, null);
            }
            ps.setString(5, rc);
            ps.setString(6, truncate(remarks, 500));
            ps.setObject(7, policy.requestedOn());
            if (policy.enlistedAt() != null) {
                ps.setObject(8, policy.enlistedAt());
            } else {
                ps.setObject(8, null);
            }
            ps.setInt(9, policy.daysEnrolled());
            ps.setString(10, policy.timingBucket());
            ps.setDouble(11, policy.chargePercent());
            ps.setDouble(12, policy.estimatedCharge());
            ps.setInt(13, policy.deadlineBlocked() ? 1 : 0);
            ps.setString(14, truncate(policy.policyNote(), 255));
            ps.setString(15, STATUS_PENDING_DEAN);
            ps.setString(16, requestedBy);
            return ps;
        }, keyHolder);
        Number key = keyHolder.getKey();
        long requestId = key != null ? key.longValue() : db.queryForObject("SELECT LAST_INSERT_ID()", Long.class);
        db.update(
            "INSERT INTO student_withdrawal_request_lines " +
                "(request_id, student_number, section_id, course_id, status) VALUES (?, ?, ?, ?, ?)",
            requestId, sn, sectionId, courseId, STATUS_PENDING_DEAN);
        documentTrailService.recordStudentEvent(
            sn,
            "STUDENT",
            "WITHDRAWAL",
            "WITHDRAWAL_REQUESTED",
            "Withdrawal request submitted",
            "Reason: " + rc + (remarks != null && !remarks.isBlank() ? ". " + truncate(remarks, 500) : "") +
                ". Request #" + requestId + ".",
            requestedBy,
            requestId,
            "student_withdrawal_requests",
            String.valueOf(requestId));
        return requestId;
    }

    @Transactional
    public DirectDropResult dropSubjectByRegistrar(String studentNumber, Integer sectionId,
                                                   String reasonCode, String remarks, String actor) {
        String sn = validateDirectDrop(studentNumber, reasonCode);
        Map<String, Object> enlistment = findActiveEnlistment(sn, sectionId);
        Integer currentTermId = requireCurrentTermId();
        if (!currentTermId.equals(numberAsInteger(enlistment.get("term_id")))) {
            throw new IllegalArgumentException("Only a current-term subject can be dropped from Student Profile.");
        }

        List<Map<String, Object>> currentLoad = findCurrentTermEnlistments(sn, currentTermId);
        if (currentLoad.size() <= 1) {
            throw new IllegalArgumentException(
                "This is the student's last current-term subject. Use Drop Student to process a full withdrawal.");
        }
        supersedePendingRequests(sn, List.of(sectionId), cleanActor(actor));
        WithdrawalPolicySnapshot policy = requireAllowedPolicy(sn, enlistment);
        String rc = clean(reasonCode).toUpperCase();
        String actedBy = cleanActor(actor);
        long requestId = insertCompletedDirectDrop(
            sn, rc, remarks, actedBy, "SINGLE_SUBJECT", List.of(enlistment), List.of(policy));

        scholarEnrollmentService.dropSubjectByEnlistmentId(
            ((Number) enlistment.get("enlistment_id")).longValue(),
            policy.estimatedCharge(), policy.policyNote());
        recordDirectDropEvents(sn, requestId, actedBy, "SINGLE_SUBJECT", List.of(enlistment),
            policy.estimatedCharge(), remarks);
        return new DirectDropResult(requestId, 1, policy.estimatedCharge(), "SINGLE_SUBJECT");
    }

    @Transactional
    public DirectDropResult dropStudentByRegistrar(String studentNumber, String reasonCode,
                                                   String remarks, String actor) {
        String sn = validateDirectDrop(studentNumber, reasonCode);
        Integer currentTermId = requireCurrentTermId();
        List<Map<String, Object>> currentLoad = findCurrentTermEnlistments(sn, currentTermId);
        if (currentLoad.isEmpty()) {
            throw new IllegalArgumentException("The student has no current-term subjects to drop.");
        }

        List<WithdrawalPolicySnapshot> policies = new ArrayList<>();
        List<Integer> sectionIds = new ArrayList<>();
        for (Map<String, Object> enlistment : currentLoad) {
            int sectionId = ((Number) enlistment.get("section_id")).intValue();
            sectionIds.add(sectionId);
            policies.add(requireAllowedPolicy(sn, enlistment));
        }

        String rc = clean(reasonCode).toUpperCase();
        String actedBy = cleanActor(actor);
        supersedePendingRequests(sn, sectionIds, actedBy);
        long requestId = insertCompletedDirectDrop(
            sn, rc, remarks, actedBy, "FULL_CURRENT_TERM", currentLoad, policies);
        double totalCharge = 0.0;
        for (int i = 0; i < currentLoad.size(); i++) {
            Map<String, Object> enlistment = currentLoad.get(i);
            WithdrawalPolicySnapshot policy = policies.get(i);
            scholarEnrollmentService.dropSubjectByEnlistmentId(
                ((Number) enlistment.get("enlistment_id")).longValue(),
                policy.estimatedCharge(), policy.policyNote());
            totalCharge += policy.estimatedCharge();
        }
        markStudentWithdrawn(sn);
        recordDirectDropEvents(sn, requestId, actedBy, "FULL_CURRENT_TERM", currentLoad, totalCharge, remarks);
        return new DirectDropResult(requestId, currentLoad.size(), totalCharge, "FULL_CURRENT_TERM");
    }

    private String validateDirectDrop(String studentNumber, String reasonCode) {
        ensureSchema();
        String sn = clean(studentNumber);
        String rc = clean(reasonCode).toUpperCase();
        if (sn.isEmpty()) throw new IllegalArgumentException("Student number is required.");
        if (rc.isEmpty()) throw new IllegalArgumentException("Drop reason is required.");
        ensureReasonExists(rc);
        String withdrawalBlock = EnrollmentPeriodPolicy.withdrawalBlockMessage(db);
        if (withdrawalBlock != null) throw new IllegalArgumentException(withdrawalBlock);
        return sn;
    }

    private WithdrawalPolicySnapshot requireAllowedPolicy(String studentNumber, Map<String, Object> enlistment) {
        WithdrawalPolicySnapshot policy = computePolicySnapshot(studentNumber, enlistment);
        if (policy.deadlineBlocked()) throw new IllegalArgumentException(policy.policyNote());
        return policy;
    }

    private Integer requireCurrentTermId() {
        Integer termId = globalTermService.getCurrentTermId();
        if (termId == null) throw new IllegalStateException("No active registrar term is configured.");
        return termId;
    }

    private List<Map<String, Object>> findCurrentTermEnlistments(String studentNumber, Integer termId) {
        return db.queryForList("""
            SELECT se.enlistment_id, se.student_id, se.course_id, se.section_id, se.enlisted_date,
                   cs.term_id, c.course_code, c.course_title, c.credit_units
            FROM student_enlistments se
            JOIN class_sections cs ON cs.section_id = se.section_id
            JOIN courses c ON c.course_id = se.course_id
            WHERE se.student_id = ? AND cs.term_id = ?
            """ + enlistmentSchemaService.enlistmentStatusFilter(
                EnlistmentSchemaService.Scope.COMMITTED_ONLY, "se") +
            " ORDER BY c.course_code, se.enlistment_id", studentNumber, termId);
    }

    private long insertCompletedDirectDrop(String studentNumber, String reasonCode, String remarks,
                                           String actor, String scope,
                                           List<Map<String, Object>> enlistments,
                                           List<WithdrawalPolicySnapshot> policies) {
        Map<String, Object> first = enlistments.get(0);
        WithdrawalPolicySnapshot firstPolicy = policies.get(0);
        double totalCharge = policies.stream().mapToDouble(WithdrawalPolicySnapshot::estimatedCharge).sum();
        KeyHolder keyHolder = new GeneratedKeyHolder();
        db.update(connection -> {
            PreparedStatement ps = connection.prepareStatement("""
                INSERT INTO student_withdrawal_requests
                    (student_number, section_id, course_id, term_id, reason_code, remarks, requested_on,
                     enlisted_at, days_enrolled_at_request, timing_bucket, charge_percent, estimated_charge,
                     deadline_blocked, policy_note, status, requested_by, registrar_approved_by,
                     registrar_approved_at, completed_at, withdrawal_scope, subject_count, approval_source)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?, ?, ?, CURRENT_TIMESTAMP,
                        CURRENT_TIMESTAMP, ?, ?, 'EXTERNAL_DEAN_FORM')
                """, new String[]{"request_id"});
            ps.setString(1, studentNumber);
            ps.setInt(2, ((Number) first.get("section_id")).intValue());
            ps.setInt(3, ((Number) first.get("course_id")).intValue());
            ps.setInt(4, ((Number) first.get("term_id")).intValue());
            ps.setString(5, reasonCode);
            ps.setString(6, truncate(remarks, 500));
            ps.setObject(7, firstPolicy.requestedOn());
            ps.setObject(8, firstPolicy.enlistedAt());
            ps.setInt(9, firstPolicy.daysEnrolled());
            ps.setString(10, scope.equals("FULL_CURRENT_TERM") ? "FULL_CURRENT_TERM" : firstPolicy.timingBucket());
            ps.setDouble(11, firstPolicy.chargePercent());
            ps.setDouble(12, totalCharge);
            ps.setString(13, truncate(firstPolicy.policyNote(), 255));
            ps.setString(14, STATUS_APPROVED);
            ps.setString(15, actor);
            ps.setString(16, actor);
            ps.setString(17, scope);
            ps.setInt(18, enlistments.size());
            return ps;
        }, keyHolder);
        Number key = keyHolder.getKey();
        long requestId = key != null ? key.longValue() : db.queryForObject("SELECT LAST_INSERT_ID()", Long.class);
        for (Map<String, Object> enlistment : enlistments) {
            db.update("""
                INSERT INTO student_withdrawal_request_lines
                    (request_id, student_number, section_id, course_id, status, completed_at)
                VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
                """, requestId, studentNumber,
                ((Number) enlistment.get("section_id")).intValue(),
                ((Number) enlistment.get("course_id")).intValue(), STATUS_APPROVED);
        }
        return requestId;
    }

    private void markStudentWithdrawn(String studentNumber) {
        db.update("UPDATE students SET admission_status = 'WITHDRAWN' WHERE student_number = ?",
            studentNumber);
        db.update("UPDATE sys_users SET admission_status = 'WITHDRAWN' WHERE username = ?",
            studentNumber);
        try {
            db.update("""
                UPDATE applicants
                SET applicant_status = 'WITHDRAWN', updated_at = CURRENT_TIMESTAMP
                WHERE reference_number = (
                    SELECT reference_number FROM students WHERE student_number = ?
                )
                """, studentNumber);
        } catch (Exception ignored) {
            db.update("""
                UPDATE applicants
                SET applicant_status = 'WITHDRAWN'
                WHERE reference_number = (
                    SELECT reference_number FROM students WHERE student_number = ?
                )
                """, studentNumber);
        }
    }

    private void recordDirectDropEvents(String studentNumber, long requestId, String actor, String scope,
                                        List<Map<String, Object>> enlistments, double totalCharge,
                                        String remarks) {
        String courses = enlistments.stream()
            .map(row -> String.valueOf(row.get("course_code")))
            .reduce((left, right) -> left + ", " + right)
            .orElse("none");
        String summary = scope.equals("FULL_CURRENT_TERM")
            ? "Student dropped from current term"
            : "Subject dropped by Registrar";
        String details = String.format("%s | Subjects: %s | Applied charge: PHP %,.2f%s",
            scope, courses, totalCharge,
            remarks != null && !remarks.isBlank() ? " | " + truncate(remarks, 300) : "");
        documentTrailService.recordStudentEvent(
            studentNumber, "STUDENT", "WITHDRAWAL", "WITHDRAWAL_COMPLETED", summary,
            details, actor, requestId, "student_withdrawal_requests", String.valueOf(requestId));
        regFormEventService.recordEvent(
            studentNumber, "WITHDRAWAL_COMPLETED", summary, requestId, details, actor);
    }

    private Integer numberAsInteger(Object value) {
        return value instanceof Number number ? number.intValue() : null;
    }

    private String cleanActor(String actor) {
        String cleaned = clean(actor);
        return cleaned.isEmpty() ? "registrar" : truncate(cleaned, 100);
    }

    private void ensureReasonExists(String reasonCode) {
        Integer count = db.queryForObject(
            "SELECT COUNT(*) FROM withdrawal_reasons WHERE reason_code = ? AND COALESCE(is_active, 1) = 1",
            Integer.class, reasonCode);
        if (count == null || count == 0) {
            throw new IllegalArgumentException("Selected withdrawal reason is not available.");
        }
    }

    private Map<String, Object> findActiveEnlistment(String studentNumber, Integer sectionId) {
        List<Map<String, Object>> rows = db.queryForList("""
            SELECT se.enlistment_id, se.student_id, se.course_id, se.section_id, se.enlisted_date,
                   cs.term_id, c.course_code, c.course_title, c.credit_units
            FROM student_enlistments se
            JOIN class_sections cs ON cs.section_id = se.section_id
            JOIN courses c ON c.course_id = se.course_id
            WHERE se.student_id = ? AND se.section_id = ?
            LIMIT 1
            """, studentNumber, sectionId);
        if (rows.isEmpty()) {
            throw new IllegalArgumentException("The selected subject is not currently enlisted for this student.");
        }
        return rows.get(0);
    }

    private WithdrawalPolicySnapshot computePolicySnapshot(String studentNumber, Map<String, Object> enlistment) {
        LocalDate requestedOn = LocalDate.now();
        LocalDateTime enlistedAt = toLocalDateTime(enlistment.get("enlisted_date"));
        int daysEnrolled = enlistedAt != null
            ? Math.max(0, (int) ChronoUnit.DAYS.between(enlistedAt.toLocalDate(), requestedOn))
            : 0;
        Integer termId = enlistment.get("term_id") instanceof Number n ? n.intValue() : null;
        boolean afterMidterm = isAfterMidterm(termId, requestedOn);
        double units = enlistment.get("credit_units") instanceof Number n ? n.doubleValue() : 0.0;
        double originalCost = units * safeTuitionRate(studentNumber);
        int halfDays = readEnrollmentSettingInt("drop_penalty_days_half", 14);
        int fullDays = readEnrollmentSettingInt("drop_penalty_days_full", 21);
        double firstWeekPct = readEnrollmentSettingDouble("drop_penalty_first_week_percent", 25.0);
        double halfPct = readEnrollmentSettingDouble("drop_penalty_half_percent", 50.0);

        if (afterMidterm) {
            return new WithdrawalPolicySnapshot(
                requestedOn, enlistedAt, daysEnrolled, "AFTER_MIDTERM_BLOCKED",
                100.0, originalCost, true,
                "Withdrawal deadline has passed. Requests are allowed only until the midterm exam date.");
        }
        if (daysEnrolled >= fullDays) {
            return new WithdrawalPolicySnapshot(
                requestedOn, enlistedAt, daysEnrolled, "FULL_CHARGE",
                100.0, originalCost, false,
                "Full tuition charge applies after " + fullDays + " enrolled day(s).");
        }
        if (daysEnrolled >= halfDays) {
            return new WithdrawalPolicySnapshot(
                requestedOn, enlistedAt, daysEnrolled, "PARTIAL_HALF",
                halfPct, originalCost * (halfPct / 100.0), false,
                String.format("%.0f%% tuition charge applies after %d enrolled day(s).", halfPct, halfDays));
        }
        if (daysEnrolled > 0) {
            return new WithdrawalPolicySnapshot(
                requestedOn, enlistedAt, daysEnrolled, "PARTIAL_FIRST_WEEK",
                firstWeekPct, originalCost * (firstWeekPct / 100.0), false,
                String.format("%.0f%% tuition charge applies within the first two weeks.", firstWeekPct));
        }
        return new WithdrawalPolicySnapshot(
            requestedOn, enlistedAt, daysEnrolled, "NO_CHARGE",
            0.0, 0.0, false,
            "No withdrawal tuition charge applies on the enlistment date.");
    }

    private LocalDateTime toLocalDateTime(Object raw) {
        if (raw instanceof java.sql.Timestamp ts) return ts.toLocalDateTime();
        if (raw instanceof LocalDateTime dt) return dt;
        return null;
    }

    private boolean isAfterMidterm(Integer termId, LocalDate requestedOn) {
        if (termId == null) return false;
        try {
            LocalDate midtermDate = null;
            try {
                midtermDate = toLocalDate(db.queryForObject(
                    "SELECT midterm_exam_date FROM academic_term_policies WHERE term_id = ? LIMIT 1",
                    Object.class, termId));
            } catch (Exception ignored) {
            }
            if (midtermDate != null) {
                return requestedOn.isAfter(midtermDate);
            }
            Map<String, Object> term = db.queryForMap(
                "SELECT start_date, end_date FROM academic_terms WHERE term_id = ? LIMIT 1", termId);
            LocalDate start = toLocalDate(term.get("start_date"));
            LocalDate end = toLocalDate(term.get("end_date"));
            if (start == null || end == null || end.isBefore(start)) return false;
            LocalDate midpoint = start.plusDays(ChronoUnit.DAYS.between(start, end) / 2);
            return requestedOn.isAfter(midpoint);
        } catch (Exception e) {
            return false;
        }
    }

    private LocalDate toLocalDate(Object raw) {
        if (raw instanceof java.sql.Date d) return d.toLocalDate();
        if (raw instanceof LocalDate d) return d;
        return null;
    }

    private double safeTuitionRate(String studentNumber) {
        try {
            return scholarEnrollmentService.tuitionRatePerUnit(studentNumber);
        } catch (Exception e) {
            return 0.0;
        }
    }

    private int readEnrollmentSettingInt(String key, int defaultValue) {
        try {
            Integer v = db.queryForObject(
                "SELECT CAST(setting_value AS SIGNED) FROM enrollment_settings WHERE setting_key = ? LIMIT 1",
                Integer.class, key);
            return v != null ? v : defaultValue;
        } catch (Exception e) {
            return defaultValue;
        }
    }

    private double readEnrollmentSettingDouble(String key, double defaultValue) {
        try {
            Double v = db.queryForObject(
                "SELECT CAST(setting_value AS DECIMAL(12,2)) FROM enrollment_settings WHERE setting_key = ? LIMIT 1",
                Double.class, key);
            return v != null ? v : defaultValue;
        } catch (Exception e) {
            return defaultValue;
        }
    }

    private void ensureNoActiveRequest(String studentNumber, Integer sectionId) {
        Integer count = db.queryForObject(
            "SELECT COUNT(*) FROM student_withdrawal_requests " +
                "WHERE student_number = ? AND section_id = ? " +
                "AND (status = ? OR status = ?)",
            Integer.class, studentNumber, sectionId, STATUS_PENDING_DEAN, STATUS_PENDING_REGISTRAR);
        if (count != null && count > 0) {
            throw new IllegalArgumentException("This subject already has a pending withdrawal request.");
        }
    }

    private void supersedePendingRequests(String studentNumber, List<Integer> sectionIds, String actor) {
        for (Integer sectionId : sectionIds) {
            List<Long> requestIds = db.queryForList(
                "SELECT request_id FROM student_withdrawal_requests " +
                    "WHERE student_number = ? AND section_id = ? AND (status = ? OR status = ?)",
                Long.class, studentNumber, sectionId, STATUS_PENDING_DEAN, STATUS_PENDING_REGISTRAR);
            for (Long requestId : requestIds) {
                db.update(
                    "UPDATE student_withdrawal_request_lines SET status = ? WHERE request_id = ?",
                    STATUS_SUPERSEDED, requestId);
                db.update(
                    "UPDATE student_withdrawal_requests SET status = ?, rejected_by = ?, " +
                        "rejected_at = CURRENT_TIMESTAMP, rejection_reason = ? WHERE request_id = ?",
                    STATUS_SUPERSEDED, actor,
                    "Superseded by direct Registrar processing of the Dean-approved paper form.", requestId);
            }
        }
    }

    @Transactional
    public String deanApprove(long requestId, String approvedBy) {
        ensureSchema();
        int updated = db.update(
            "UPDATE student_withdrawal_requests " +
                "SET status = ?, dean_approved_by = ?, dean_approved_at = CURRENT_TIMESTAMP " +
                "WHERE request_id = ? AND BINARY status = BINARY ?",
            STATUS_PENDING_REGISTRAR, clean(approvedBy), requestId, STATUS_PENDING_DEAN);
        if (updated == 0) return "Withdrawal request is no longer pending Dean approval.";
        db.update("UPDATE student_withdrawal_request_lines SET status = ? WHERE request_id = ?",
            STATUS_PENDING_REGISTRAR, requestId);
        Map<String, Object> trailRow = loadRequestForTrail(requestId);
        if (trailRow != null) {
            documentTrailService.recordStudentEvent(
                String.valueOf(trailRow.get("student_number")),
                "STUDENT",
                "WITHDRAWAL",
                "WITHDRAWAL_DEAN_APPROVED",
                "Withdrawal forwarded to Registrar",
                "Request #" + requestId + " approved by Dean and queued for final registrar approval.",
                clean(approvedBy),
                requestId,
                "student_withdrawal_requests",
                String.valueOf(requestId));
        }
        return "Withdrawal request forwarded to Registrar approval.";
    }

    @Transactional
    public Map<String, Object> prepareRegistrarApproval(long requestId, String approvedBy) {
        ensureSchema();
        List<Map<String, Object>> rows = db.queryForList(
            "SELECT wr.request_id, wr.student_number, wr.section_id, wr.status, wr.estimated_charge, " +
                "wr.policy_note, wr.timing_bucket, c.course_code " +
                "FROM student_withdrawal_requests wr " +
                "LEFT JOIN courses c ON c.course_id = wr.course_id " +
                "WHERE wr.request_id = ?",
            requestId);
        if (rows.isEmpty()) throw new IllegalArgumentException("Withdrawal request not found.");
        Map<String, Object> row = rows.get(0);
        if (!STATUS_PENDING_REGISTRAR.equals(row.get("status"))) {
            throw new IllegalArgumentException("Withdrawal request is not pending Registrar approval.");
        }
        findActiveEnlistment(String.valueOf(row.get("student_number")), ((Number) row.get("section_id")).intValue());
        db.update(
            "UPDATE student_withdrawal_requests " +
                "SET registrar_approved_by = ?, registrar_approved_at = CURRENT_TIMESTAMP " +
                "WHERE request_id = ? AND BINARY status = BINARY ?",
            clean(approvedBy), requestId, STATUS_PENDING_REGISTRAR);
        documentTrailService.recordStudentEvent(
            String.valueOf(row.get("student_number")),
            "STUDENT",
            "WITHDRAWAL",
            "WITHDRAWAL_REGISTRAR_APPROVED",
            "Withdrawal approved by Registrar",
            "Request #" + requestId + " approved. Estimated charge: PHP " +
                String.format("%,.2f", row.get("estimated_charge") instanceof Number n ? n.doubleValue() : 0.0) + ".",
            clean(approvedBy),
            requestId,
            "student_withdrawal_requests",
            String.valueOf(requestId));
        return row;
    }

    @Transactional
    public void markCompleted(long requestId) {
        ensureSchema();
        db.update(
            "UPDATE student_withdrawal_requests SET status = ?, completed_at = CURRENT_TIMESTAMP " +
                "WHERE request_id = ?",
            STATUS_APPROVED, requestId);
        db.update(
            "UPDATE student_withdrawal_request_lines SET status = ?, completed_at = CURRENT_TIMESTAMP " +
                "WHERE request_id = ?",
            STATUS_APPROVED, requestId);
        Map<String, Object> trailRow = loadRequestForTrail(requestId);
        if (trailRow != null) {
            documentTrailService.recordStudentEvent(
                String.valueOf(trailRow.get("student_number")),
                "STUDENT",
                "WITHDRAWAL",
                "WITHDRAWAL_COMPLETED",
                "Withdrawal completed",
                "Request #" + requestId + " completed and the subject was removed from the student's load.",
                String.valueOf(trailRow.getOrDefault("registrar_approved_by", trailRow.getOrDefault("dean_approved_by", "registrar"))),
                requestId,
                "student_withdrawal_requests",
                String.valueOf(requestId));
        }
    }

    @Transactional
    public String reject(long requestId, String rejectedBy, String reason) {
        ensureSchema();
        int updated = db.update(
            "UPDATE student_withdrawal_requests " +
                "SET status = ?, rejected_by = ?, rejected_at = CURRENT_TIMESTAMP, rejection_reason = ? " +
                "WHERE request_id = ? AND (BINARY status = BINARY ? OR BINARY status = BINARY ?)",
            STATUS_REJECTED, clean(rejectedBy), truncate(reason, 500), requestId,
            STATUS_PENDING_DEAN, STATUS_PENDING_REGISTRAR);
        if (updated == 0) return "Withdrawal request is no longer pending.";
        db.update("UPDATE student_withdrawal_request_lines SET status = ? WHERE request_id = ?",
            STATUS_REJECTED, requestId);
        Map<String, Object> trailRow = loadRequestForTrail(requestId);
        if (trailRow != null) {
            documentTrailService.recordStudentEvent(
                String.valueOf(trailRow.get("student_number")),
                "STUDENT",
                "WITHDRAWAL",
                "WITHDRAWAL_REJECTED",
                "Withdrawal request rejected",
                reason != null && !reason.isBlank()
                    ? "Request #" + requestId + " rejected: " + truncate(reason, 500)
                    : "Request #" + requestId + " rejected.",
                clean(rejectedBy),
                requestId,
                "student_withdrawal_requests",
                String.valueOf(requestId));
        }
        return "Withdrawal request rejected.";
    }

    public Map<String, Long> statusCounts() {
        ensureSchema();
        Map<String, Long> counts = new java.util.LinkedHashMap<>();
        counts.put(STATUS_PENDING_DEAN, 0L);
        counts.put(STATUS_PENDING_REGISTRAR, 0L);
        counts.put(STATUS_APPROVED, 0L);
        counts.put(STATUS_REJECTED, 0L);
        counts.put(STATUS_SUPERSEDED, 0L);
        for (Map<String, Object> row : db.queryForList(
                "SELECT status, COUNT(*) AS cnt FROM student_withdrawal_requests GROUP BY status")) {
            counts.put(String.valueOf(row.get("status")), ((Number) row.get("cnt")).longValue());
        }
        return counts;
    }

    public List<Map<String, Object>> reasonSummary() {
        ensureSchema();
        return db.queryForList("""
            SELECT COALESCE(rr.reason_label, wr.reason_code) AS reason_label,
                   COUNT(*) AS request_count,
                   COALESCE(SUM(wr.estimated_charge), 0) AS estimated_charge_total
            FROM student_withdrawal_requests wr
            LEFT JOIN withdrawal_reasons rr ON BINARY rr.reason_code = BINARY wr.reason_code
            GROUP BY COALESCE(rr.reason_label, wr.reason_code)
            ORDER BY request_count DESC, reason_label
            """);
    }

    public List<Map<String, Object>> timingSummary() {
        ensureSchema();
        return db.queryForList("""
            SELECT COALESCE(timing_bucket, 'UNCLASSIFIED') AS timing_bucket,
                   COUNT(*) AS request_count,
                   COALESCE(SUM(estimated_charge), 0) AS estimated_charge_total
            FROM student_withdrawal_requests
            GROUP BY COALESCE(timing_bucket, 'UNCLASSIFIED')
            ORDER BY request_count DESC, timing_bucket
            """);
    }

    private String clean(String value) {
        return value != null ? value.trim() : "";
    }

    private String truncate(String value, int max) {
        if (value == null) return null;
        String trimmed = value.trim();
        return trimmed.length() <= max ? trimmed : trimmed.substring(0, max);
    }

    private Map<String, Object> loadRequestForTrail(long requestId) {
        try {
            List<Map<String, Object>> rows = db.queryForList(
                "SELECT request_id, student_number, requested_by, dean_approved_by, registrar_approved_by " +
                    "FROM student_withdrawal_requests WHERE request_id = ? LIMIT 1",
                requestId);
            return rows.isEmpty() ? null : rows.get(0);
        } catch (Exception e) {
            return null;
        }
    }

    private record WithdrawalPolicySnapshot(LocalDate requestedOn,
                                            LocalDateTime enlistedAt,
                                            int daysEnrolled,
                                            String timingBucket,
                                            double chargePercent,
                                            double estimatedCharge,
                                            boolean deadlineBlocked,
                                            String policyNote) {
    }

    public record DirectDropResult(long requestId, int subjectsDropped,
                                   double totalCharge, String scope) {
    }
}
