# Registrar Term System Implementation Handoff

Date: 2026-06-03

## Scope

This handoff documents the registrar-side term-system work completed from the original analysis in `registrar_term_system_analysis.md`. It is intended for the next agent, especially if they are realigning the connected enrollment system.

The registrar work focused on making global term transition safe, auditable, and gated by term readiness. Enrollment schedule-conflict behavior is intentionally left for the enrollment-side follow-up.

## Implemented Registrar Updates

### 1. Active Term Readiness Gate

The System Settings page now computes readiness for the selected target term before allowing global transition.

Readiness checks:
- Active programs with `active_status = 1`
- Active curriculum per program
- Exact term fee rows for every active program, year level 1-4, semester 1-2
- Missing fee scopes
- Fallback fee scopes
- Required fee tables

Affected files:
- `src/main/java/com/iuims/registrar/service/TermFeeAdminService.java`
- `src/main/java/com/iuims/registrar/controller/AcademicController.java`
- `src/main/resources/templates/admin_settings.html`

Verified in the UI:
- Readiness reached `Ready`
- `Missing fee scopes = 0`
- `Fallback fee scopes = 0`

### 2. Global Term Transition Hardening

Global transition now validates the target `academic_terms` row before changing `CURRENT_ACADEMIC_TERM`.

Safety behaviors:
- Normalizes `SL_*` term codes before DB lookup
- Resolves a real `academic_terms.term_id`
- Blocks transition unless readiness is green
- Activates the target term row by `term_id`
- Deactivates all other term rows
- Updates `system_settings.CURRENT_ACADEMIC_TERM` only after successful target validation/activation
- Preserves student `student_type` when present
- Does not clear existing debt blocking carelessly
- Forwards unpaid balances into the new term ledger flow

Affected files:
- `src/main/java/com/iuims/registrar/service/AcademicGradingService.java`
- `src/main/java/com/iuims/registrar/controller/AcademicController.java`

Verified in the UI:
- Transition to `A.Y. 2027-2028 - 2nd Semester` succeeded
- Green confirmation appeared
- Active readiness remained green after transition

### 3. Fee Preparation and Template Copy Tools

Program Fees now has bulk repair actions:
- `Prepare term fees`
- `Copy imported program templates`

`Prepare term fees`:
- Creates exact term fee rows where values can be inferred
- Copies fallback `MISC_*` and `OTHER_*` rows into exact term rows
- Does not overwrite exact term rows
- Reports created/copied/unable counts

`Copy imported program templates`:
- Copies fee templates from base programs into imported/specialized programs with no fee history
- Does not overwrite existing exact term rows
- Example mappings include business specializations from `BSBA`

Affected files:
- `src/main/java/com/iuims/registrar/service/TermFeeAdminService.java`
- `src/main/java/com/iuims/registrar/controller/TermFeeAdminController.java`
- `src/main/resources/templates/admin_term_fees.html`

Verified in the UI:
- Bulk preparation cleared hundreds of fallback/missing fee warnings
- Template copy cleared the remaining imported-program fee warnings

### 4. Fee Lookup Precedence Cleanup

Exact term-specific fee rows now win over fallback fee rows, even when fallback rows were inserted later.

Affected files:
- `src/main/java/com/iuims/registrar/service/TermFeeAdminService.java`
- `src/main/java/com/iuims/registrar/service/ScholarEnrollmentService.java`

### 5. Curriculum Seeder Canonicalization and Repair

Curriculum seeding now maps known document-derived program codes to the registrar's canonical program codes where possible.

Also added `Repair readiness curricula`, which:
- Deactivates duplicate alias programs such as `ABCOM`
- Moves active curriculum templates from aliases to canonical programs when applicable
- Creates active placeholder curriculum templates for canonical programs with no bundled `.docx`

Affected files:
- `src/main/java/com/iuims/registrar/service/CurriculumSeederService.java`
- `src/main/java/com/iuims/registrar/controller/CurriculumController.java`
- `src/main/resources/templates/admin_curriculum.html`

Verified in the UI:
- Curriculum warnings disappeared after repair
- Program count normalized from imported duplicates to a ready active set

### 6. Removed Hardcoded Term Fallbacks

Hardcoded fallback term usage was removed from the scholar/cashier path. Missing term configuration now surfaces as a warning instead of silently using an old term.

Affected files:
- `src/main/java/com/iuims/registrar/controller/ScholarController.java`
- `src/main/java/com/iuims/registrar/service/ScholarEnrollmentService.java`
- `src/main/resources/templates/admin_scholar_walkin.html`

## Real Run Observations

Term transitioned:
- From prior active term into `A.Y. 2027-2028 - 2nd Semester`

Example student checked:
- Student: `2026-0009`
- Name: `Dela Cruz, Juan`
- Program: `BSIT`

Observed after transition:
- Student term became `SL_2420272028`
- Student standing became Year 4 / 2nd Semester
- Ledger showed the new active term
- Prior balance was forwarded into the new term ledger context
- Enlistment page loaded Year 4 / Sem 2 subjects
- Section assignment worked for `BSIT-4-2-A`

## Enrollment-Side Follow-Up

The enrollment conflict seen after registrar transition is a separate scheduling/enlistment issue, not a registrar term-readiness issue.

For the next agent, start with:

- `handoff/03-agent-dev/ENROLLMENT_REALIGNMENT_BRIEF.md`

That brief is the shortest path to assessing both the enrollment system behavior and the remaining cross-system gaps.

Observed conflict:
- `UCP2 42` Capstone Project 2
- `UOJT 42` On the Job Training
- Conflict reason: `Schedule conflict with Capstone Project 2`

Known schedule overlap:
- `UCP2 42`: Monday `07:30-09:00` and Monday `10:00-11:30`
- `UOJT 42`: Monday `09:00-10:30`
- Overlap: Monday `10:00-10:30`

Enrollment-side next agent should:
- Adjust the `UOJT 42` schedule, or
- Add a non-conflicting alternate `UOJT 42` section, or
- Revisit OJT conflict policy if OJT is intended to be exempt/manual.

Do not treat this as a registrar transition failure. The registrar transition and readiness gate worked as intended.

## Tests Run

Command:

```powershell
& 'C:\Users\admin\.m2\wrapper\dists\apache-maven-3.9.14\ed7edd442f634ac1c1ef5ba2b61b6d690b5221091f1a8e1123f5fadcc967520d\bin\mvn.cmd' test
```

Latest result:
- Tests run: `13`
- Failures: `0`
- Errors: `0`
- Skipped: `0`

Test files added/updated:
- `src/test/java/com/iuims/registrar/service/TermFeeAdminServiceTest.java`
- `src/test/java/com/iuims/registrar/service/AcademicGradingServiceTermTransitionTest.java`

## Important Compatibility Notes

Shared tables enrollment depends on:
- `academic_terms`
- `system_settings.CURRENT_ACADEMIC_TERM`
- `program_general_fees`
- `program_specific_fees`
- `students.term_year`
- `sys_users.term_year`
- `student_enlistments`
- `payments`
- `student_ledger`

Term-code convention preserved:
- DB term code: `2420272028`
- System setting/student term code: `SL_2420272028`

Fee behavior to preserve:
- Exact term rows should win over fallback rows
- Fallback rows may be displayed, but readiness must not be green while fallback rows are still needed
- Bulk preparation/template copy must not overwrite exact term rows

Curriculum behavior to preserve:
- Registrar currently treats curriculum as program-global, not term-specific
- Readiness requires one active curriculum per active program

## Suggested Next Registrar Improvements

These are optional future registrar-side improvements:
- Add a durable transition audit table instead of relying only on flash messages
- Add a term setup wizard that combines readiness, fee preparation, curriculum repair, and final transition
- Add clearer program alias governance so imported `.docx` files cannot create duplicate active program codes
- Decide whether curriculum should remain program-global or become term-scoped
- Decide whether non-`MISC`/`OTHER` fee groups should be exposed in registrar UI
