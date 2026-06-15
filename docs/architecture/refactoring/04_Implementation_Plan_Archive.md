# Architecture Refactoring: Implementation Plan Archive

This document is the **canonical implementation plan** that was designed and executed during the architectural overhaul. It is preserved here verbatim (with post-execution annotations) as the authoritative record of what was planned, why, and how each decision was made.

---

## 1. Problem Statement

The `registrar` service arrived in a state that made further development increasingly dangerous:

- `AcademicGradingService` (a single class, ~2000+ lines) was responsible for every domain in the system — grading, term management, user management, scholarship forwarding, class scheduling, and more.
- All state mutations occurred via raw `JdbcTemplate` SQL strings, with no compile-time schema validation.
- `BeanCurrentlyInCreationException` at startup was masked with `@Lazy` but never resolved.
- Adding MCP (`@Tool`) annotations to methods that execute raw SQL would expose the AI to unstructured, injection-prone operations.

---

## 2. Phase Sequencing and Rationale

### Phase 1: Decouple via Events (Priority: BLOCKING)

**Why first?** The cyclic dependency was the most dangerous active defect. If the Spring context couldn't reliably boot, no other work could be validated. This had to be the first and blocking step.

**What was done:**
- Defined `TermTransitionEvent` as an immutable record in the `academic` package.
- Replaced `AcademicGradingService`'s direct call to `ScholarEnrollmentService.forwardBalancesToNextTerm()` with `eventPublisher.publishEvent(new TermTransitionEvent(...))`.
- Added `@EventListener void onTermTransition(TermTransitionEvent)` in `ScholarEnrollmentService`.
- Removed the `@Lazy` annotation from the injected `ScholarEnrollmentService` reference.
- Verified Spring context booted cleanly.

### Phase 2: Migrate Cross-Boundary JDBC Mutations (Priority: HIGH)

**Why second?** Before we could safely run any tests, all writes to tables outside the `academic` bounded context had to go through the proper module's repository. Otherwise `@DataJpaTest` tests would fail trying to use JPA entities while JDBC mutates the same rows in parallel.

**What was done:**
- Created/expanded `SysUserRepository` in `core` with methods: `findByUsername`, `findByRoleAndIsActiveAndAdmissionStatusIn`, `deleteById`.
- Created/expanded `StudentRepository` in `core` with: `searchStudents`, `findByStudentNumber`.
- Replaced all `db.update("UPDATE sys_users ...")` calls in `AcademicGradingService` with `sysUserRepository.save(user)`.
- Replaced `db.update("UPDATE students ...")` calls with `studentRepository.save(student)`.

### Phase 3: Full JPA Migration for Owned Mutations (Priority: HIGH)

**Why third?** With cross-boundary writes eliminated, we turned to the `academic` module's own tables. This was the largest phase in terms of raw code volume.

**What was done:**
- Created `AcademicTermRepository`, `AcademicTermPolicyRepository`, `GradingTermWindowRepository`.
- Created `GradeRepository`, `GradeChangeRequestRepository`, `VpaaExtensionRepository`.
- Created `ClassSectionRepository`, `ClassScheduleRepository`.
- Created `SystemSettingRepository` and `TermTransitionAuditRepository`.
- For each of the above: mapped the corresponding database table to a JPA `@Entity`, and rewrote all `db.update(...)` and `db.execute(...)` calls in `AcademicGradingService` to use the new repositories.
- Read-only `db.queryForList(...)` and `db.queryForObject(...)` calls were **deliberately retained** for complex projection queries (CQRS-lite pattern — see `03_JPA_Migration.md` for rationale).

### Phase 4: MCP Integration (Priority: NORMAL — depends on Phase 1-3)

**Why last?** The MCP `@Tool` annotation must only be applied to methods that go through the JPA layer. Phases 1-3 had to complete first to ensure no annotated method executes raw SQL.

**What was done:** See `docs/architecture/mcp/` for the full MCP integration plan and walkthrough.

---

## 3. Decisions Made and Alternatives Rejected

### Decision: Use `ApplicationEventPublisher` for cross-module calls
**Alternative rejected**: Introduce a dedicated interface (`AcademicEventPort`) in `core` that `scholarship` implements via dependency injection.
**Why rejected**: The event pattern is simpler, requires no shared interface, and is the standard Spring Modulith mechanism. An interface port would still result in a bi-directional dependency if both modules referenced the port.

### Decision: Retain read-only JDBC (`db.queryForList`)
**Alternative rejected**: Convert all JDBC to JPA entity graphs.
**Why rejected**: N+1 query risk on multi-table projections outweighed the consistency benefit. Read-only JDBC carries no mutation risk.

### Decision: Use `saveAndFlush()` instead of `save()` for all mutations
**Why**: `saveAndFlush()` commits immediately within the transaction, catching constraint violations eagerly. `save()` defers to the end of the transaction, which can cause confusing errors at unexpected points.

---

## 4. Risk Mitigation

| Risk | Mitigation Applied |
|---|---|
| Breaking existing controller-to-service contracts | No public method signatures were changed. Only implementations were refactored. |
| Type mismatches between JPA entity fields and test H2 DDL | Each test's `@BeforeEach` DDL was audited and updated when new entities were introduced |
| `@DataJpaTest` not auto-creating H2 schema | Manual DDL in `@BeforeEach` is the established pattern; documented in `regression-verification/03_Technical_Documentation.md` |
| Raw SQL reads becoming stale | Only mutable SQL was migrated; reads remain as fast JDBC projections |
