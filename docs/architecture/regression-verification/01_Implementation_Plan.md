# Regression Verification: Implementation Plan

## Goal

Before officially closing the architectural refactoring and MCP integration phases, a systematic regression verification was executed to prove that the refactored codebase (`projects-20260604T124931Z-3-001`) is behaviourally equivalent to — or better than — the original monolith (`projectsOld`).

This document describes the verification strategy, the dimensions of comparison, and the analytical methodology used.

---

## Background & Motivation

A refactoring of this scope — migrating from raw `JdbcTemplate` to Spring Data JPA, restructuring from a single-package monolith to a Spring Modulith, and introducing an event-driven decoupling pattern — carries a non-trivial risk of introducing silent regressions.

> [!IMPORTANT]
> Silent regressions are the most dangerous outcome of a large-scale refactoring. A method may be renamed, a parameter silently dropped, or a query result slightly different in type (e.g., `Long` vs `Integer`) — and none of these will cause a compilation error.

The verification plan was designed to catch regressions at **four independent layers**:

1. **HTTP API Layer** — Are all controller routes identical?
2. **Service Method Layer** — Are all public business methods preserved?
3. **Template Layer** — Is all UI rendering identical?
4. **Automated Test Layer** — Do all unit tests pass against the refactored code?

---

## Verification Dimensions

### Dimension 1: HTTP API Parity
**Method**: Extract all `@GetMapping`, `@PostMapping`, `@RequestMapping` annotations from every controller in both the old (`controller/`) and new (`portal/`) packages. Compare side by side.

**Rationale**: The HTTP contract is the outermost boundary of the application. If a route changes, every dependent client (browser, external integrations) breaks silently. A controller endpoint audit provides direct evidence that the web-facing API is preserved.

**Scope**: `AcademicController`, `EnrollmentController`, `PortalController`, `ScholarController`, `TermFeeAdminController`.

### Dimension 2: Public Service Method Parity
**Method**: Extract all `public` method signatures from key services in both old and new, sort them, and compare.

**Rationale**: Controllers call service methods by name. Any removed or renamed method will cause a runtime `NoSuchMethodError` or a compile error in tests — or worse, silently fall through to a default. Direct method signature comparison is the most reliable way to verify the service contract.

**Scope**: `AcademicGradingService`, `ScholarEnrollmentService`, `TermFeeAdminService`.

### Dimension 3: Template Parity
**Method**: Use PowerShell `Compare-Object` on the sorted file lists from both template directories.

**Rationale**: Thymeleaf templates define the UI contract. Missing or renamed templates result in `TemplateInputException` at runtime. File-level parity comparison verifies zero templates were accidentally dropped.

### Dimension 4: Automated Unit Test Suite
**Method**: Run `mvn test` against the full refactored project. All 44 tests must pass with `Failures: 0, Errors: 0`.

**Rationale**: The existing test suite was written against the original business logic and data expectations. If the refactoring changed behaviour, the tests will detect it. This is the most authoritative verification layer.

---

## Expected Outcomes

- **Endpoints**: 100% preserved, with at most additive-only new endpoints.
- **Service Methods**: 100% preserved. Any renaming must be accompanied by a full impact analysis of all callers.
- **Templates**: 100% preserved.
- **Tests**: `44/44 PASS`, `BUILD SUCCESS`.

---

## Risk Areas Anticipated

| Risk | Mitigation |
|---|---|
| JPA vs JDBC returning different Java types (e.g., `Long` vs `Integer`) | Examine test assertion types carefully |
| New JPA entities not reflected in H2 test DDL | Audit all `@Entity` classes and verify DDL in `@BeforeEach` |
| Faculty lookup stubbed out during refactoring | Inspect `getPendingClassSubmissions` and equivalent methods for TODOs |
| Method renamed without updating all callers | Search all controller and test files for the old method name |
