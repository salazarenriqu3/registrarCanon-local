# JPA Migration: Securing the Data Layer

## The Problem: Unchecked SQL and Schema Drift

The legacy codebase heavily relied on Spring JDBC (`JdbcTemplate`) — referenced as the `db` field — to execute raw SQL strings directly within business logic services, especially `AcademicGradingService`. This service alone contained hundreds of `db.update(...)`, `db.queryForList(...)`, and `db.queryForObject(...)` calls scattered across thousands of lines.

This approach had three critical failure modes:

1. **Schema Drift**: When the database schema changed (e.g., adding `granted_permissions` to `sys_users`, or adding `grading_term_windows` as a new table), raw SQL strings failed silently at runtime with `InvalidDataAccessResourceUsage` or `Table not found` errors — never caught at compile time.

2. **Architectural Boundary Violations**: The `academic` module directly mutated tables owned by other modules. For example:
   - `db.update("UPDATE sys_users SET semester=?, year_level=? WHERE username=?", ...)` — mutating `core` module data from within `academic`.
   - `db.update("INSERT INTO student_debts ...")` — inserting into `scholarship`-owned tables from `academic`.

3. **No Type Safety**: Query results were returned as `Map<String, Object>`, forcing every consumer to do manual casting (`(Integer) row.get("term_id")`), which produced `ClassCastException` at runtime when types differed between MySQL and H2.

---

## The Solution: Spring Data JPA Repositories

We undertook a systematic multi-phase migration to eliminate all **state-mutating** JDBC calls and replace them with Spring Data JPA.

### New JPA Entities Created

| Entity Class | Table | Module | Purpose |
|---|---|---|---|
| `AcademicTerm` | `academic_terms` | `academic` | Term lifecycle management |
| `AcademicTermPolicy` | `academic_term_policies` | `academic` | Per-term INC expiration dates |
| `GradingTermWindow` | `grading_term_windows` | `academic` | Per-term grading period windows (PRELIM/MIDTERM/FINAL) |
| `Grade` | `grades` | `core` | Student grade records with JPA lifecycle |
| `GradeChangeRequest` | `grade_change_requests` | `academic` | Grade correction/reopen requests |
| `ClassSection` | `class_sections` | `academic` | Course sections per term |
| `ClassSchedule` | `class_schedules` | `academic` | Day/time schedule rows per section |
| `SysUser` | `sys_users` | `core` | System users (students, faculty, admin) |
| `Student` | `students` | `core` | Student profile records |
| `SystemSetting` | `system_settings` | `core` | Key-value application settings |
| `VpaaExtension` | `vpaa_extensions` | `academic` | VPAA grading window extension requests |
| `TermTransitionAudit` | `term_transition_audit` | `academic` | Audit log of term transition attempts |

### New Repositories Created

| Repository | Module | Key Methods |
|---|---|---|
| `AcademicTermRepository` | `academic` | `findByTermCode`, `findByIsActive` |
| `AcademicTermPolicyRepository` | `academic` | `findByTermId` |
| `GradingTermWindowRepository` | `academic` | `findByTermIdAndGradingPeriod` |
| `GradeRepository` | `core` | `findBySectionId`, `findByStudentId` |
| `GradeChangeRequestRepository` | `academic` | `findByStatus`, `findByGradeId` |
| `ClassSectionRepository` | `academic` | `findBySectionStatus`, `findByCourseIdAndTermId` |
| `ClassScheduleRepository` | `academic` | `findBySectionId` |
| `SysUserRepository` | `core` | `findByUsername`, `findByRoleAndIsActiveAndAdmissionStatusIn` |
| `StudentRepository` | `core` | `searchStudents`, `findByStudentNumber` |
| `SystemSettingRepository` | `core` | `findById` (key-value by setting key) |
| `VpaaExtensionRepository` | `academic` | `findPendingExtensions`, `findByScheduleIdAndStatus` |
| `TermTransitionAuditRepository` | `academic` | `save` |

---

## Migration Example: Grade Approval Workflow

### Before (Raw JDBC — Violation of Module Boundaries):
```java
// AcademicGradingService - direct SQL across multiple owned tables
db.update("UPDATE grades SET registrar_final_grade=?, registrar_final_remarks=?, " +
          "grade_lock_status='GRADE_CHANGE_APPROVED' WHERE id=?",
          newGrade, remarks, gradeId);
db.update("UPDATE grade_change_requests SET status='APPROVED', approved_at=NOW() " +
          "WHERE request_id=?", requestId);
```

### After (Spring Data JPA — Clean & Type-Safe):
```java
Grade grade = gradeRepository.findById(gradeId).orElseThrow();
grade.setRegistrarFinalGrade(BigDecimal.valueOf(newGrade));
grade.setRegistrarFinalRemarks(remarks);
grade.setGradeLockStatus("GRADE_CHANGE_APPROVED");
gradeRepository.saveAndFlush(grade);

GradeChangeRequest request = gradeChangeRequestRepository.findById(requestId).orElseThrow();
request.setStatus("APPROVED");
request.setApprovedAt(LocalDateTime.now());
gradeChangeRequestRepository.saveAndFlush(request);
```

---

## Deliberate Decision: Read-Only JDBC Retained (CQRS-Lite)

> [!IMPORTANT]
> Not all JDBC was removed. Read-only aggregate queries (`db.queryForList(...)`) were **deliberately retained** for complex multi-table read projections. This is an intentional design pattern.

Examples of retained JDBC reads:
- `getCoursesWithSections(int termId)` — 3-table join with nested schedule rows
- `getStudentAcademicHistory(String studentNumber)` — complex grade history projection
- `getAllFacultyForScheduling()` — joins `faculty` with `departments`

**Why this is correct:**
- These are **read-only** operations. They carry zero risk of schema boundary violations.
- Mapping these as JPA `@EntityGraph` queries would introduce N+1 select problems and require artificial `@OneToMany` relationships that do not belong in the entity model.
- The CQRS pattern (Command Query Responsibility Segregation) explicitly endorses using the most efficient read mechanism for queries, while using the domain model for all writes.
- Future agents **must not** attempt to convert these reads to JPA without a clear performance trade-off analysis.

---

## Why This Migration Matters

- **Data Integrity**: JPA manages transactions, validates constraints, and uses `saveAndFlush()` to catch constraint violations immediately rather than at commit time.
- **Bounded Contexts Enforced Physically**: Because `AcademicGradingService` must now use `SysUserRepository.save(user)` instead of `db.update("UPDATE sys_users ...")`, the compiler itself prevents boundary violations — not just code review.
- **AI Readiness**: MCP `@Tool` methods backed by JPA cannot execute arbitrary SQL. Every operation goes through the Java domain model, ensuring AI-invoked writes respect all business constraints and validation rules.
