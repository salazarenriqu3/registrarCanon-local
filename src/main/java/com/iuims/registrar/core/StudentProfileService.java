package com.iuims.registrar.core;

import jakarta.annotation.PostConstruct;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.StringJoiner;

@Service
public class StudentProfileService {

    private final JdbcTemplate db;

    private static final LinkedHashMap<String, String> EDITABLE_FIELDS = new LinkedHashMap<>();

    static {
        EDITABLE_FIELDS.put("first_name", "First name");
        EDITABLE_FIELDS.put("middle_name", "Middle name");
        EDITABLE_FIELDS.put("last_name", "Last name");
        EDITABLE_FIELDS.put("real_name", "Display name");
        EDITABLE_FIELDS.put("email", "Email");
        EDITABLE_FIELDS.put("mobile", "Mobile");
        EDITABLE_FIELDS.put("sex", "Sex");
        EDITABLE_FIELDS.put("dob", "Date of birth");
        EDITABLE_FIELDS.put("place_of_birth", "Place of birth");
        EDITABLE_FIELDS.put("civil_status", "Civil status");
        EDITABLE_FIELDS.put("religion", "Religion");
        EDITABLE_FIELDS.put("nationality", "Nationality");
        EDITABLE_FIELDS.put("citizenship", "Citizenship");
        EDITABLE_FIELDS.put("street", "Street address");
        EDITABLE_FIELDS.put("city", "City");
        EDITABLE_FIELDS.put("province", "Province");
        EDITABLE_FIELDS.put("zip", "ZIP");
        EDITABLE_FIELDS.put("emergency_contact_name", "Emergency contact");
        EDITABLE_FIELDS.put("emergency_contact_mobile", "Emergency mobile");
        EDITABLE_FIELDS.put("emergency_contact_relationship", "Emergency relationship");
        EDITABLE_FIELDS.put("father_name", "Father name");
        EDITABLE_FIELDS.put("father_occupation", "Father occupation");
        EDITABLE_FIELDS.put("father_contact", "Father contact");
        EDITABLE_FIELDS.put("father_address", "Father address");
        EDITABLE_FIELDS.put("mother_name", "Mother name");
        EDITABLE_FIELDS.put("mother_occupation", "Mother occupation");
        EDITABLE_FIELDS.put("mother_contact", "Mother contact");
        EDITABLE_FIELDS.put("mother_address", "Mother address");
        EDITABLE_FIELDS.put("guardian_name", "Guardian name");
        EDITABLE_FIELDS.put("guardian_contact", "Guardian contact");
        EDITABLE_FIELDS.put("guardian_relationship", "Guardian relationship");
        EDITABLE_FIELDS.put("elementary_school", "Elementary school");
        EDITABLE_FIELDS.put("elementary_address", "Elementary address");
        EDITABLE_FIELDS.put("elementary_year", "Elementary year");
        EDITABLE_FIELDS.put("jhs_school", "Junior high school");
        EDITABLE_FIELDS.put("jhs_address", "Junior high address");
        EDITABLE_FIELDS.put("jhs_year", "Junior high year");
        EDITABLE_FIELDS.put("shs_school", "Senior high school");
        EDITABLE_FIELDS.put("shs_address", "Senior high address");
        EDITABLE_FIELDS.put("shs_track", "Senior high track");
        EDITABLE_FIELDS.put("shs_year", "Senior high year");
        EDITABLE_FIELDS.put("last_school", "Last school");
        EDITABLE_FIELDS.put("last_school_year", "Last school year");
        EDITABLE_FIELDS.put("course_taken", "Course taken");
    }

    public StudentProfileService(JdbcTemplate db) {
        this.db = db;
    }

    @PostConstruct
    public void init() {
        ensureSchema();
    }

    public void ensureSchema() {
        db.execute(
            "CREATE TABLE IF NOT EXISTS students (" +
                "student_number VARCHAR(100) NOT NULL PRIMARY KEY, " +
                "user_id INT NULL, reference_number VARCHAR(100) NULL, " +
                "first_name VARCHAR(100) NULL, middle_name VARCHAR(100) NULL, last_name VARCHAR(100) NULL, " +
                "real_name VARCHAR(200) NULL, email VARCHAR(150) NULL, mobile VARCHAR(50) NULL, " +
                "program_code VARCHAR(100) NULL, year_level INT DEFAULT 1, semester INT DEFAULT 1, " +
                "term_year VARCHAR(50) NULL, student_type VARCHAR(50) NULL, enrollment_status_type VARCHAR(50) NULL, " +
                "admission_status VARCHAR(50) NULL, scholarship_type VARCHAR(50) NULL, " +
                "scholarship_approved TINYINT(1) DEFAULT 0, scholarship_amount DECIMAL(10,2) DEFAULT 0.00, " +
                "discount_percentage DECIMAL(5,2) DEFAULT 0.00, section_group VARCHAR(10) NULL, " +
                "status VARCHAR(50) DEFAULT 'ACTIVE', is_active TINYINT(1) DEFAULT 1, " +
                "enrollment_blocked TINYINT(1) DEFAULT 0, password VARCHAR(255) NULL, role VARCHAR(30) DEFAULT 'STUDENT')"
        );

        tryExecute("ALTER TABLE students ADD COLUMN sex VARCHAR(10) NULL");
        tryExecute("ALTER TABLE students ADD COLUMN dob VARCHAR(20) NULL");
        tryExecute("ALTER TABLE students ADD COLUMN place_of_birth TEXT NULL");
        tryExecute("ALTER TABLE students ADD COLUMN civil_status VARCHAR(30) NULL");
        tryExecute("ALTER TABLE students ADD COLUMN religion VARCHAR(60) NULL");
        tryExecute("ALTER TABLE students ADD COLUMN nationality VARCHAR(60) NULL");
        tryExecute("ALTER TABLE students ADD COLUMN citizenship VARCHAR(60) NULL");
        tryExecute("ALTER TABLE students ADD COLUMN street TEXT NULL");
        tryExecute("ALTER TABLE students ADD COLUMN city VARCHAR(100) NULL");
        tryExecute("ALTER TABLE students ADD COLUMN province VARCHAR(100) NULL");
        tryExecute("ALTER TABLE students ADD COLUMN zip VARCHAR(20) NULL");
        tryExecute("ALTER TABLE students ADD COLUMN emergency_contact_name VARCHAR(150) NULL");
        tryExecute("ALTER TABLE students ADD COLUMN emergency_contact_mobile VARCHAR(30) NULL");
        tryExecute("ALTER TABLE students ADD COLUMN emergency_contact_relationship VARCHAR(60) NULL");
        tryExecute("ALTER TABLE students ADD COLUMN father_name VARCHAR(150) NULL");
        tryExecute("ALTER TABLE students ADD COLUMN father_occupation VARCHAR(100) NULL");
        tryExecute("ALTER TABLE students ADD COLUMN father_contact VARCHAR(30) NULL");
        tryExecute("ALTER TABLE students ADD COLUMN father_address TEXT NULL");
        tryExecute("ALTER TABLE students ADD COLUMN mother_name VARCHAR(150) NULL");
        tryExecute("ALTER TABLE students ADD COLUMN mother_occupation VARCHAR(100) NULL");
        tryExecute("ALTER TABLE students ADD COLUMN mother_contact VARCHAR(30) NULL");
        tryExecute("ALTER TABLE students ADD COLUMN mother_address TEXT NULL");
        tryExecute("ALTER TABLE students ADD COLUMN guardian_name VARCHAR(150) NULL");
        tryExecute("ALTER TABLE students ADD COLUMN guardian_contact VARCHAR(30) NULL");
        tryExecute("ALTER TABLE students ADD COLUMN guardian_relationship VARCHAR(60) NULL");
        tryExecute("ALTER TABLE students ADD COLUMN elementary_school TEXT NULL");
        tryExecute("ALTER TABLE students ADD COLUMN elementary_address TEXT NULL");
        tryExecute("ALTER TABLE students ADD COLUMN elementary_year VARCHAR(20) NULL");
        tryExecute("ALTER TABLE students ADD COLUMN jhs_school TEXT NULL");
        tryExecute("ALTER TABLE students ADD COLUMN jhs_address TEXT NULL");
        tryExecute("ALTER TABLE students ADD COLUMN jhs_year VARCHAR(20) NULL");
        tryExecute("ALTER TABLE students ADD COLUMN shs_school TEXT NULL");
        tryExecute("ALTER TABLE students ADD COLUMN shs_address TEXT NULL");
        tryExecute("ALTER TABLE students ADD COLUMN shs_track VARCHAR(60) NULL");
        tryExecute("ALTER TABLE students ADD COLUMN shs_year VARCHAR(20) NULL");
        tryExecute("ALTER TABLE students ADD COLUMN last_school TEXT NULL");
        tryExecute("ALTER TABLE students ADD COLUMN last_school_year VARCHAR(20) NULL");
        tryExecute("ALTER TABLE students ADD COLUMN course_taken VARCHAR(100) NULL");
        tryExecute("ALTER TABLE students ADD COLUMN scholarship_type VARCHAR(50) NULL");
        tryExecute("ALTER TABLE students ADD COLUMN scholarship_approved TINYINT(1) DEFAULT 0");
        tryExecute("ALTER TABLE students ADD COLUMN scholarship_amount DECIMAL(10,2) DEFAULT 0.00");
        tryExecute("ALTER TABLE students ADD COLUMN discount_percentage DECIMAL(5,2) DEFAULT 0.00");
        tryExecute("ALTER TABLE students ADD COLUMN section_group VARCHAR(10) NULL");
        tryExecute("ALTER TABLE students ADD COLUMN status VARCHAR(50) DEFAULT 'ACTIVE'");
        tryExecute("ALTER TABLE students ADD COLUMN is_active TINYINT(1) DEFAULT 1");
        tryExecute("ALTER TABLE students ADD COLUMN enrollment_blocked TINYINT(1) DEFAULT 0");
        ensureSysUserProfileColumns();
    }

    public Map<String, Object> getEditableProfile(String studentNumber) {
        ensureSchema();
        Set<String> applicantColumns = existingColumns("applicants");
        String select = buildProfileSelect(applicantColumns);
        String applicantJoin = applicantColumns.isEmpty()
            ? " "
            : " LEFT JOIN applicants a ON a.reference_number = s.reference_number ";
        try {
            return db.queryForMap(
                "SELECT s.student_number, s.reference_number, " + select +
                    " FROM students s" + applicantJoin +
                    "WHERE s.student_number = ? LIMIT 1",
                studentNumber);
        } catch (Exception e) {
            return new LinkedHashMap<>();
        }
    }

    @Transactional
    public List<String> updateProfile(String studentNumber, Map<String, String> form) {
        ensureSchema();
        Map<String, Object> before = getEditableProfile(studentNumber);
        Map<String, String> values = readEditableValues(form);
        if (isBlank(values.get("real_name"))) {
            values.put("real_name", buildRealName(values));
        }

        updateStudentColumns(studentNumber, values);
        syncSysUser(studentNumber, values);

        List<String> changed = new ArrayList<>();
        for (Map.Entry<String, String> field : EDITABLE_FIELDS.entrySet()) {
            String oldValue = normalizeValue(before.get(field.getKey()));
            String newValue = normalizeValue(values.get(field.getKey()));
            if (!oldValue.equals(newValue)) {
                changed.add(field.getValue());
            }
        }
        return changed;
    }

    @Transactional
    public void copyApplicantProfile(String studentNumber, String referenceNumber) {
        ensureSchema();
        try {
            Map<String, Object> applicant = db.queryForMap(
                "SELECT * FROM applicants WHERE reference_number = ? LIMIT 1",
                referenceNumber);
            Map<String, String> values = new LinkedHashMap<>();
            for (String field : EDITABLE_FIELDS.keySet()) {
                values.put(field, normalizeValue(applicant.get(field)));
            }
            if (isBlank(values.get("real_name"))) {
                values.put("real_name", buildRealName(values));
            }
            updateStudentColumns(studentNumber, values);
            syncSysUser(studentNumber, values);
        } catch (Exception ignored) {
        }
    }

    private String buildProfileSelect(Set<String> applicantColumns) {
        StringJoiner joiner = new StringJoiner(", ");
        for (String field : EDITABLE_FIELDS.keySet()) {
            if ("real_name".equals(field)) {
                if (applicantColumns.contains("first_name") && applicantColumns.contains("middle_name") && applicantColumns.contains("last_name")) {
                    joiner.add("COALESCE(NULLIF(s.real_name, ''), NULLIF(TRIM(CONCAT(COALESCE(a.first_name, ''), ' ', COALESCE(a.middle_name, ''), ' ', COALESCE(a.last_name, ''))), '')) AS real_name");
                } else {
                    joiner.add("s.real_name AS real_name");
                }
            } else if (applicantColumns.contains(field)) {
                joiner.add("COALESCE(NULLIF(s." + field + ", ''), a." + field + ") AS " + field);
            } else {
                joiner.add("s." + field + " AS " + field);
            }
        }
        return joiner.toString();
    }

    private Map<String, String> readEditableValues(Map<String, String> form) {
        Map<String, String> values = new LinkedHashMap<>();
        for (String field : EDITABLE_FIELDS.keySet()) {
            values.put(field, clean(form.get(field)));
        }
        return values;
    }

    private void updateStudentColumns(String studentNumber, Map<String, String> values) {
        StringJoiner setters = new StringJoiner(", ");
        List<Object> args = new ArrayList<>();
        for (String field : EDITABLE_FIELDS.keySet()) {
            setters.add(field + " = ?");
            args.add(values.get(field));
        }
        args.add(studentNumber);
        db.update(
            "UPDATE students SET " + setters + " WHERE student_number = ?",
            args.toArray());
    }

    private void syncSysUser(String studentNumber, Map<String, String> values) {
        Set<String> sysUserColumns = existingColumns("sys_users");
        LinkedHashMap<String, String> syncValues = new LinkedHashMap<>();
        addIfColumnExists(syncValues, sysUserColumns, "real_name", values.get("real_name"));
        addIfColumnExists(syncValues, sysUserColumns, "email", values.get("email"));
        addIfColumnExists(syncValues, sysUserColumns, "mobile", values.get("mobile"));
        addIfColumnExists(syncValues, sysUserColumns, "first_name", values.get("first_name"));
        addIfColumnExists(syncValues, sysUserColumns, "middle_name", values.get("middle_name"));
        addIfColumnExists(syncValues, sysUserColumns, "last_name", values.get("last_name"));
        if (syncValues.isEmpty()) {
            return;
        }

        StringJoiner setters = new StringJoiner(", ");
        List<Object> args = new ArrayList<>();
        syncValues.forEach((field, value) -> {
            setters.add(field + " = ?");
            args.add(value);
        });
        args.add(studentNumber);
        try {
            db.update(
                "UPDATE sys_users SET " + setters + " WHERE username = ?",
                args.toArray());
        } catch (Exception ignored) {
        }
    }

    private void addIfColumnExists(Map<String, String> target, Set<String> columns, String field, String value) {
        if (columns.contains(field)) {
            target.put(field, value);
        }
    }

    private void ensureSysUserProfileColumns() {
        tryExecute("ALTER TABLE sys_users ADD COLUMN first_name VARCHAR(100) NULL");
        tryExecute("ALTER TABLE sys_users ADD COLUMN middle_name VARCHAR(100) NULL");
        tryExecute("ALTER TABLE sys_users ADD COLUMN last_name VARCHAR(100) NULL");
        tryExecute("ALTER TABLE sys_users ADD COLUMN email VARCHAR(150) NULL");
        tryExecute("ALTER TABLE sys_users ADD COLUMN mobile VARCHAR(50) NULL");
        tryExecute("ALTER TABLE sys_users ADD COLUMN term_year VARCHAR(50) NULL");
        tryExecute("ALTER TABLE sys_users ADD COLUMN student_type VARCHAR(50) NULL");
        tryExecute("ALTER TABLE sys_users ADD COLUMN enrollment_status_type VARCHAR(50) NULL");
    }

    private Set<String> existingColumns(String tableName) {
        Set<String> columns = new HashSet<>();
        try {
            db.queryForList(
                "SELECT LOWER(COLUMN_NAME) AS column_name FROM INFORMATION_SCHEMA.COLUMNS WHERE LOWER(TABLE_NAME) = LOWER(?)",
                tableName)
                .forEach(row -> columns.add(String.valueOf(row.get("column_name")).toLowerCase()));
        } catch (Exception ignored) {
        }
        return columns;
    }

    private String buildRealName(Map<String, String> values) {
        StringJoiner joiner = new StringJoiner(" ");
        addIfPresent(joiner, values.get("first_name"));
        addIfPresent(joiner, values.get("middle_name"));
        addIfPresent(joiner, values.get("last_name"));
        return joiner.length() > 0 ? joiner.toString() : null;
    }

    private void addIfPresent(StringJoiner joiner, String value) {
        if (!isBlank(value)) {
            joiner.add(value.trim());
        }
    }

    private String clean(String value) {
        if (value == null) return null;
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private String normalizeValue(Object value) {
        return value == null ? "" : value.toString().trim();
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private void tryExecute(String sql) {
        try {
            db.execute(sql);
        } catch (Exception ignored) {
        }
    }
}
