# Enrollment Realignment Brief

Date: 2026-06-03

## Purpose

This brief is for the next agent who will inspect and realign the **enrollment system** after the registrar term transition was verified successfully.

The registrar-side readiness work is complete. The remaining work is to validate the enrollment app for:

- current-term scoping bugs in code
- term-mapping/data inconsistencies
- schedule-policy questions that may be intentional business rules

## Verified Registrar State

- Global term transition succeeded for `A.Y. 2027-2028 - 2nd Semester`.
- Student `2026-0009` (`Dela Cruz, Juan`) advanced correctly to `SL_2420272028`.
- Registrar readiness is green:
  - `Missing fee scopes = 0`
  - `Fallback fee scopes = 0`
  - `Ready for operation`

Do not reopen registrar readiness, fee repair, curriculum repair, or the global term transition unless the enrollment investigation finds a shared-contract mismatch.

## What The Enrollment Agent Should Assume

This is **not** a database-only cleanup.

There are still code paths in the enrollment system that need review and likely updates, especially around subject management and new-student auto-enlist. The agent should expect to inspect and possibly modify code, not just data.

## Known Enrollment-Side Observation

Student checked after transition:
- `2026-0009` / `Dela Cruz, Juan`
- Program: `BSIT`

Observed enlistment conflict:
- `UCP2 42` = Capstone Project 2
- `UOJT 42` = On the Job Training
- Conflict reason: `Schedule conflict with Capstone Project 2`

Known overlap:
- `UCP2 42`: Monday `07:30-09:00` and Monday `10:00-11:30`
- `UOJT 42`: Monday `09:00-10:30`
- Overlap window: Monday `10:00-10:30`

This may be valid policy, or it may mean OJT needs a manual/exempt flow. Treat that as an enrollment-side validation question, not a registrar failure.

## Enrollment Code Paths That Still Need Review

### 1. Current-term subject management

Inspect:
- `src/main/java/com/example/enrollment/controller/RegistrarController.java`
  - `manageSubjects(...)`
- `src/main/java/com/example/enrollment/service/EnrollmentIntegrationService.java`
  - `getStudentLoad(...)`
  - `getCrossSystemAnalyzedOfferings(...)`

Why:
- `currentSubjects` should reflect the resolved current term, not the student’s entire history.
- `availableSubjects` should be scoped to the same resolved term.
- Historical enlistments should not appear as current-term subjects on a current-term screen.

Current risk:
- `getStudentLoad(...)` still returns enlistments without a `term_id` filter.
- `manageSubjects(...)` still derives `availableSubjects` from the registrar active term instead of the student-resolved term.

### 2. New-student regular auto-enlist

Inspect:
- `src/main/java/com/example/enrollment/controller/RegistrarController.java`
  - regular auto-enlist query in `completeEnrollment(...)`

Why:
- The query should choose sections from the intended term only.
- Duplicate blocking should only block the same course in the same term.
- Prior-term enrollment should not suppress current-term enrollment for the same course.

Current risk:
- The query still lacks `cs.term_id = ?`.
- Duplicate prevention is still global by `course_id`, not term-scoped.

### 3. Safe fallback behavior

Inspect:
- `src/main/java/com/example/enrollment/service/EnrollmentIntegrationService.java`
- any caller that uses the no-term overloads

Why:
- Current-term screens should not silently fall back to global-history queries.
- Historical views may keep fallback behavior only when they are explicitly historical.

Current risk:
- Some overloads still route to a `null` term id path that can fall back to all-history behavior.

### 4. Term resolution contract

Inspect:
- `src/main/java/com/example/enrollment/service/TermContextService.java`
- any caller that maps `students.term_year`, `sys_users.term_year`, or `academic_terms.term_code`

Expected rule:
- Prefer `resolveTermIdForStudent(student)` first.
- Use registrar active term only as fallback when the student cannot be mapped.
- Do not rely on loose string comparison if `term_id` is available.

## What To Verify In Data Versus Code

Some issues are code issues. Some are data/policy issues. The agent should separate them:

### Code-side issues
- Current-term subject list leaks historical load.
- Available subjects are scoped to the registrar active term instead of the student-resolved term.
- New-student auto-enlist is not term-scoped.

### Data/policy issues
- Check whether term codes on `students`, `sys_users`, and `academic_terms` line up with the resolver.
- Decide whether OJT is allowed to be manually exempt from schedule conflict checks.
- Confirm whether the schedule conflict for `UOJT 42` is intentional or a bad section setup.

## Assessment Questions For The Enrollment Agent

1. Does the enrollment UI still show historical subjects on a current-term subject management screen?
2. Does the new-student auto-enlist query still pull sections from the wrong term or block current-term duplicates because of prior-term rows?
3. Is the `UOJT 42` conflict intentional policy, or should OJT be exempt/manual?
4. Are any enrollment paths still relying on global-history fallback when they should be term-specific?
5. Do the term identifiers stored in the enrollment database map cleanly to the registrar active term?

## What Good Looks Like

- Current-term screens only show the resolved current term.
- Same-term duplicate blocks remain in place.
- Prior-term history does not consume current-term unit capacity.
- Schedule conflict policy is unchanged unless the business decides OJT should be exempt.
- Enrollment and registrar both agree on the same term boundary.

## Do Not Reopen

- Registrar term readiness
- Fee repair
- Curriculum repair
- Global term transition

Those are already completed and verified on the registrar side.
