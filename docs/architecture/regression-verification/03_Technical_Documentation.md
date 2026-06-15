# Regression Verification: Technical Documentation

This document is written as a **technical guide for future agents** operating within this repository. It establishes the regression testing methodology, known schema patterns, and the reasoning behind the fixes applied during the verification phase.

---

## 1. Test Architecture Overview

The project uses two distinct test contexts:

### `@DataJpaTest` (Unit Tests)
Used in `AcademicGradingServiceGradingWindowTest` and `AcademicGradingServiceTermTransitionTest`. These tests:
- Bootstrap a real Spring Application Context with JPA repositories wired.
- Use an **H2 in-memory database** (not MySQL).
- Manually create schema via `db.execute(CREATE TABLE ...)` in `@BeforeEach`.
- Import the service under test via `@Import({AcademicGradingService.class, ...})`.

> [!WARNING]
> **Critical agent constraint**: Because the schema is defined manually via DDL strings in `@BeforeEach`, every time a new `@Entity` class is added to the project, **its corresponding `CREATE TABLE` statement must also be added to the test's `@BeforeEach` setup**. Hibernate does NOT auto-create the schema in `@DataJpaTest` mode unless `spring.jpa.hibernate.ddl-auto=create` is explicitly set.

### `ModulithTests` (Integration Test)
Uses `@SpringBootTest` and attempts to connect to a real MySQL instance. This test will produce a `CJCommunicationsException: Communications link failure` in development environments where MySQL is not running, but is expected to succeed (0 failures, 0 errors) because it handles the connection failure gracefully. **Do not treat this MySQL error as a test failure.**

---

## 2. Known Schema Requirements for H2 Test Context

The following tables **must** be present in the `@BeforeEach` DDL block for the `AcademicGradingServiceGradingWindowTest` test class to pass:

| Table | Mapped Entity | Notes |
|---|---|---|
| `academic_terms` | `AcademicTerm` | Include `is_active`, `status`, `term_code`, `term_name`, `academic_year`, `semester_number` |
| `system_settings` | `SystemSetting` | `setting_key VARCHAR PK`, `setting_value VARCHAR` |
| `sys_users` | `SysUser` | Must include `granted_permissions` column — added during JPA refactoring |
| `students` | `Student` | Full schema including all `Student` entity fields |
| `grades` | `Grade` | `id` is `INT` (not `BIGINT`) — affects assertion types |
| `grade_change_requests` | `GradeChangeRequest` | |
| `class_sections` | `ClassSection` | |
| `class_schedules` | `ClassSchedule` | |
| `courses` | `Course` | |
| `faculty` | *(not a JPA entity)* | Used for raw JDBC lookup in `getPendingClassSubmissions` |
| `grading_term_windows` | `GradingTermWindow` | **Added during JPA refactoring** — must be in DDL |
| `academic_term_policies` | `AcademicTermPolicy` | **Added during JPA refactoring** — must be in DDL |

---

## 3. Type Mapping Pitfalls

When the test layer and JPA layer disagree on data types, assertions silently fail with confusing messages. Known pitfalls:

| Field | JPA Entity Type | Common Mistake | Correct Assertion |
|---|---|---|---|
| `Grade.id` | `Integer` | `.isEqualTo(300L)` (Long) | `.isEqualTo(300)` (Integer) |
| `Grade.prelim` | `BigDecimal` → mapped to `double` in service | `.isEqualTo(BigDecimal)` | `.isEqualTo(88.0)` (double) |
| `SysUser.isActive` | `Boolean` | `.isEqualTo(1)` (int) | `.isEqualTo(true)` (Boolean) |

---

## 4. Faculty Lookup Pattern in `getPendingClassSubmissions`

The `getPendingClassSubmissions` method resolves faculty names using a **dual-lookup strategy**. This is a deliberate design decision documented here for future agents:

```java
String facultyName = "";
if (cs.getFacultyId() != null) {
    // Primary: query the dedicated faculty table via JDBC
    try {
        facultyName = db.queryForObject(
            "SELECT CONCAT(COALESCE(first_name,''), ' ', COALESCE(last_name,'')) FROM faculty WHERE faculty_id = ?",
            String.class, cs.getFacultyId());
    } catch (Exception ignored) {
        // Fallback: resolve via sys_users (admin/staff faculty)
        facultyName = sysUserRepository.findById(cs.getFacultyId())
            .map(SysUser::getRealName).orElse("");
    }
}
```

**Why dual-lookup?** The `faculty` table stores full-time teaching staff. Some sections may be taught by admin users registered in `sys_users`. The fallback ensures both cases are covered without a join that crosses module boundaries.

---

## 5. How to Run Regression Verification

To re-run a full regression check at any time:

```bash
# Step 1: Compile verification
mvn clean test -DskipTests

# Step 2: Full test suite
mvn test

# Expected output:
# Tests run: 44, Failures: 0, Errors: 0, Skipped: 0
# BUILD SUCCESS
```

If new `@Entity` classes are added and tests break with `Table "..." not found`, follow this procedure:

1. Identify the table name from the error message (e.g., `GRADING_TERM_WINDOWS`).
2. Find the corresponding `@Entity` class and its `@Table(name = "...")` annotation.
3. Reproduce the DDL `CREATE TABLE` statement for H2 compatibility (use `VARCHAR`, `INT`, `DECIMAL`, `DATE`, `TIMESTAMP` — avoid MySQL-specific types like `TINYINT(1)` for booleans; use `BOOLEAN` instead).
4. Add it to the `@BeforeEach` setUp in the affected test class.

---

## 6. Regression Verification Checklist (for Future Agents)

When performing a regression check after any significant code change, use this checklist:

- [ ] **Endpoints**: Compare `@GetMapping`/`@PostMapping` annotations in all controllers against the expected baseline.
- [ ] **Service Methods**: Extract `public` method signatures from key services and compare counts and names.
- [ ] **Templates**: Run `Compare-Object` on template directory listings from old vs new.
- [ ] **Compilation**: `mvn clean test -DskipTests` → must produce `BUILD SUCCESS`.
- [ ] **Unit Tests**: `mvn test` → must produce `Failures: 0, Errors: 0`.
- [ ] **Type Assertions**: When a test fails with `expected: X but was: Y`, check if the underlying JPA entity type changed (Long vs Integer, Boolean vs int, etc.).
- [ ] **Schema Completeness**: When `Table "..." not found`, add missing DDL to `@BeforeEach`.
