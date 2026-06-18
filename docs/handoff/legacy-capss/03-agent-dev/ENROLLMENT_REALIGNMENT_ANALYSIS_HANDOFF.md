# Enrollment Realignment Analysis Handoff

Date: 2026-06-03

## Scope

This handoff documents the enrollment-side analysis and code changes completed in response to:

- `docs/handoff/legacy-capss/03-agent-dev/ENROLLMENT_REALIGNMENT_BRIEF.md`

The goal of this pass was to realign current-term enrollment behavior so registrar-facing current-term workflows use the student's resolved current `term_id`, not all-history enlistments and not the registrar active term by default.

No controller routes, request parameters, response DTOs, or template contracts were changed.

## Summary Outcome

The main code-side issues called out in the brief were addressed:

- current-term subject management is now term-scoped
- current-term subject load no longer leaks historical enlistments
- regular new-student auto-enlist is now term-scoped
- current-term offering loaders no longer silently fall back to global-history behavior when no term resolves

The schedule-conflict policy was intentionally not changed.

The remaining open items are data verification and business-rule confirmation, not the core term-scoping code paths.

## Brief-to-Implementation Mapping

### 1. Current-term subject management

Brief concern:

- `RegistrarController.manageSubjects(...)` was using the registrar active term
- `currentSubjects` could show historical rows
- `availableSubjects` could be scoped to the wrong term

Implemented:

- `RegistrarController.manageSubjects(...)` now resolves the student's term with `TermContextService.resolveTermIdForStudent(student)`
- if no term resolves, the screen now receives:
  - `currentSubjects = []`
  - `availableSubjects = []`
  - an explicit error message
- `EnrollmentIntegrationService.getStudentLoad(...)` now filters by `class_sections.term_id = resolved current term`
- `EnrollmentIntegrationService.getCrossSystemAnalyzedOfferings(...)` now returns empty when no term is provided/resolved, instead of falling back to historical behavior

Affected files:

- `C:\Users\admin\Downloads\6126\projects\enrollment3\src\main\java\com\example\enrollment\controller\RegistrarController.java`
- `C:\Users\admin\Downloads\6126\projects\enrollment3\src\main\java\com\example\enrollment\service\EnrollmentIntegrationService.java`

### 2. New-student regular auto-enlist

Brief concern:

- regular auto-enlist could choose sections from the wrong term
- duplicate prevention was global by `course_id`, not same-term

Implemented:

- added `cs.term_id = ?` to the regular auto-enlist query
- duplicate prevention now joins `class_sections` and blocks duplicates only within the same resolved term
- if a regular student's current term cannot be resolved, enrollment now stops with an explicit error instead of proceeding with ambiguous term selection

Affected file:

- `C:\Users\admin\Downloads\6126\projects\enrollment3\src\main\java\com\example\enrollment\controller\RegistrarController.java`

### 3. Safe fallback behavior

Brief concern:

- no-term overloads could route into null-term behavior and return all-history results on current-term screens

Implemented:

- `EnrollmentIntegrationService.getCrossSystemAnalyzedOfferings(studentNumber)` now resolves the student's current term by default
- `EnrollmentIntegrationService.getCrossSystemAnalyzedOfferings(studentNumber, boolean)` now also resolves the student's current term by default
- `EnrollmentIntegrationService.getCrossSystemAnalyzedOfferings(..., termId)` now returns an empty list if `termId` is `null`
- `AdminController.getBlockPreview(...)` now uses the student-resolved term and returns an empty list if no term resolves

Affected files:

- `C:\Users\admin\Downloads\6126\projects\enrollment3\src\main\java\com\example\enrollment\service\EnrollmentIntegrationService.java`
- `C:\Users\admin\Downloads\6126\projects\enrollment3\src\main\java\com\example\enrollment\controller\AdminController.java`

### 4. Term resolution contract

Brief expectation:

- prefer `resolveTermIdForStudent(student)` first
- use registrar active term only through the resolver fallback
- avoid loose string comparisons when `term_id` is available

Implemented status:

- current-term registrar subject management now follows this contract
- current-term offering preview now follows this contract
- current-term manual add logic now validates that the chosen section belongs to the student's resolved current term
- the canonical internal rule used in this pass is `TermContextService.resolveTermIdForStudent(student)`

## Additional Guardrails Added

### Manual add protection

The brief emphasized preserving same-term duplicate blocking and avoiding wrong-term current flows.

To support that:

- `EnrollmentIntegrationService.addSubjectCrossSystem(...)` now returns an explicit error if no current term resolves
- the method now checks the selected section's `term_id`
- the method blocks adding a section from a different term than the student's resolved current term

Preserved behavior:

- same-term duplicate course block remains in place
- prerequisite behavior remains unchanged
- schedule-conflict behavior remains unchanged
- unit-limit behavior remains current-term scoped

## What Was Explicitly Preserved

Per the brief, these behaviors were intentionally left as-is:

- `addSubjectCrossSystem()` same-term duplicate blocking logic was preserved conceptually and kept term-scoped
- `EnrollmentController.showAccountStatus()` was not changed in this pass
- schedule-conflict policy was not relaxed for OJT/manual exemptions
- no historical/reporting views were intentionally expanded or rewritten

## Verification Performed

Code verification completed:

- traced all main callers of `getCrossSystemAnalyzedOfferings(...)`
- updated current-term callers that were still relying on registrar-active-term or null-term behavior
- checked that the modified source compiles successfully

Build command used:

```powershell
.\mvnw.cmd -DskipTests compile
```

Result:

- build succeeded

What was not completed in this pass:

- no scenario-based integration test run against live/shared database data
- no new unit test suite was added for these paths
- no business-rule decision was made for OJT schedule-conflict exemptions

## Open Questions Still Remaining

These items from the brief remain follow-up work rather than code regressions in the updated paths:

### 1. Data alignment check

Still verify whether:

- `students.term_year`
- `sys_users.term_year`
- `academic_terms.term_code`

all map cleanly through the enrollment resolver for real student records after transition.

### 2. OJT schedule-conflict policy

Observed issue from the brief remains open:

- `UCP2 42` conflicts with `UOJT 42`
- overlap includes Monday `10:00-10:30`

This pass did not override or exempt OJT from schedule-conflict validation.

Decision still needed:

- keep current conflict behavior as intended policy, or
- provide a manual/exempt OJT flow, or
- change section setup to remove the overlap

### 3. Real-data confirmation

Recommended follow-up checks in the live/demo environment:

- student with prior-term enlistments but no current-term load should see no historical rows on current-term subject management
- course taken in a prior term but offered again now should still appear if not already enlisted this term
- regular auto-enlist should only choose sections belonging to the resolved current term
- unresolved-term cases should return empty/error state, not all-history data

## Recommended Next Steps

For the next agent:

1. Validate the updated behavior with the known student mentioned in the brief:
   - `2026-0009`
   - `Dela Cruz, Juan`
2. Inspect real values across `students`, `sys_users`, and `academic_terms` to confirm resolver mapping is clean after registrar transition.
3. Decide whether the `UOJT 42` conflict is:
   - intended policy
   - bad section setup
   - or a case requiring manual exemption workflow
4. If needed, add focused unit/integration coverage around:
   - `getStudentLoad(...)`
   - `getCrossSystemAnalyzedOfferings(...)`
   - registrar `completeEnrollment(...)` regular auto-enlist

## Do Not Reopen

Per the original brief, this pass did not reopen:

- registrar term readiness
- fee repair
- curriculum repair
- global term transition

Those remain registrar-side completed work unless a future investigation finds a true shared-contract mismatch.
