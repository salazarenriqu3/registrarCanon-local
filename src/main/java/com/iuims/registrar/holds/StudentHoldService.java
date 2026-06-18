package com.iuims.registrar.holds;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.sql.PreparedStatement;
import java.sql.Statement;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Service
public class StudentHoldService {

    public static final Set<String> ALLOWED_OFFICES = Set.of("OSA", "LIBRARY", "REGISTRAR", "FINANCE");

    private final JdbcTemplate db;

    public StudentHoldService(JdbcTemplate db) {
        this.db = db;
    }

    public void ensureSchema() {
        db.execute("""
            CREATE TABLE IF NOT EXISTS student_holds (
                hold_id BIGINT AUTO_INCREMENT PRIMARY KEY,
                student_number VARCHAR(100) NOT NULL,
                office VARCHAR(30) NOT NULL,
                reason VARCHAR(500) NOT NULL,
                active TINYINT(1) NOT NULL DEFAULT 1,
                created_by VARCHAR(100) NULL,
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                cleared_by VARCHAR(100) NULL,
                cleared_at TIMESTAMP NULL
            )
            """);
        try {
            db.execute("CREATE INDEX idx_student_holds_student ON student_holds (student_number, active)");
        } catch (Exception ignored) {
        }
    }

    public boolean hasActiveHolds(String studentNumber) {
        if (studentNumber == null || studentNumber.isBlank()) return false;
        ensureSchema();
        Integer count = db.queryForObject(
            "SELECT COUNT(*) FROM student_holds WHERE BINARY student_number = BINARY ? AND active = 1",
            Integer.class, studentNumber.trim());
        return count != null && count > 0;
    }

    public List<Map<String, Object>> listActiveHolds(String studentNumber) {
        if (studentNumber == null || studentNumber.isBlank()) return List.of();
        ensureSchema();
        return db.queryForList(
            "SELECT hold_id, student_number, office, reason, active, created_by, created_at " +
                "FROM student_holds WHERE BINARY student_number = BINARY ? AND active = 1 " +
                "ORDER BY created_at DESC, hold_id DESC",
            studentNumber.trim());
    }

    public List<Map<String, Object>> listAllHolds(String studentNumber) {
        if (studentNumber == null || studentNumber.isBlank()) return List.of();
        ensureSchema();
        return db.queryForList(
            "SELECT hold_id, student_number, office, reason, active, created_by, created_at, cleared_by, cleared_at " +
                "FROM student_holds WHERE BINARY student_number = BINARY ? " +
                "ORDER BY active DESC, created_at DESC, hold_id DESC",
            studentNumber.trim());
    }

    @Transactional
    public long addHold(String studentNumber, String office, String reason, String createdBy) {
        ensureSchema();
        String sn = clean(studentNumber);
        String off = normalizeOffice(office);
        String r = clean(reason);
        if (sn.isEmpty()) throw new IllegalArgumentException("Student number is required.");
        if (r.isEmpty()) throw new IllegalArgumentException("Hold reason is required.");

        KeyHolder keyHolder = new GeneratedKeyHolder();
        db.update(connection -> {
            PreparedStatement ps = connection.prepareStatement(
                "INSERT INTO student_holds (student_number, office, reason, active, created_by) VALUES (?, ?, ?, 1, ?)",
                Statement.RETURN_GENERATED_KEYS);
            ps.setString(1, sn);
            ps.setString(2, off);
            ps.setString(3, truncate(r, 500));
            ps.setString(4, clean(createdBy));
            return ps;
        }, keyHolder);
        Number key = keyHolder.getKey();
        return key != null ? key.longValue() : db.queryForObject("SELECT LAST_INSERT_ID()", Long.class);
    }

    @Transactional
    public boolean clearHold(long holdId, String clearedBy) {
        ensureSchema();
        int updated = db.update(
            "UPDATE student_holds SET active = 0, cleared_by = ?, cleared_at = CURRENT_TIMESTAMP " +
                "WHERE hold_id = ? AND active = 1",
            clean(clearedBy), holdId);
        return updated > 0;
    }

    private String normalizeOffice(String office) {
        String normalized = clean(office).toUpperCase();
        if (!ALLOWED_OFFICES.contains(normalized)) {
            throw new IllegalArgumentException("Office must be one of: OSA, Library, Registrar, Finance.");
        }
        return normalized;
    }

    private String clean(String value) {
        return value != null ? value.trim() : "";
    }

    private String truncate(String value, int max) {
        return value.length() <= max ? value : value.substring(0, max);
    }
}
