# Enrollment Realignment Consolidated Handoff

Date: 2026-06-04

## Purpose

This is the consolidated enrollment-side handoff for the registrar work that is already completed and verified.

It intentionally excludes only registrar items that are still in flight. The following registrar-side items are now finalized and should be treated as part of the enrollment-side contract:

- registrar schema/script alignment for the finalized term, grading, and scholarship objects
- richer grade-change request workflow expansion
- registrar reopen-for-edit workflow expansion
- scholarship eligibility and granting workflow

Use this file as the current source of truth for the next agent working on the enrollment system.

## Registrar Work Already Finalized

### 1. Global academic term transition is now readiness-gated and verified

Registrar now treats academic term transition as a guarded operation:

- target term must resolve to a real `academic_terms.term_id`
- readiness must be green before transition is allowed
- `academic_terms.is_active` is updated by real `term_id`
- `system_settings.CURRENT_ACADEMIC_TERM` is updated only after successful activation
- eligible students are advanced to the new term
- prior balances are forwarded into the new term ledger context

Verified registrar outcome:

- transitioned term: `A.Y. 2027-2028 - 2nd Semester`
- readiness reached `Ready`
- `Missing fee scopes = 0`
- `Fallback fee scopes = 0`

### 2. Fee setup now prefers exact term rows and supports bulk preparation

Registrar fee behavior now assumes:

- exact term fee rows must win over fallback rows
- fallback rows may still exist, but readiness must not be green while fallback rows are still needed
- bulk fee preparation must not overwrite existing exact term rows

Registrar added working tools for:

- `Prepare term fees`
- `Copy imported program templates`

These were used successfully to clear readiness warnings before the verified term transition.

### 3. Curriculum is now treated as a student assignment, not just a program default

Registrar now tracks the student’s active curriculum in:

```sql
student_curriculum_assignments
```

Key rule:

- `curriculum_templates.is_active = 1` is only the default curriculum for new entrants or default destination logic
- continuing students should stay on their assigned curriculum
- program shifts must result in a current destination-program curriculum assignment

Enrollment must not assume that the newest active curriculum for a program replaces all continuing students.

### 4. Program shift now includes curriculum assignment logic

Registrar program shift is no longer just a `program_code` change.

Current registrar rule:

- a shift assigns a destination curriculum
- if none is explicitly chosen, registrar uses the target program’s active/default curriculum
- prior academic history remains historical and should not be rewritten into the new program context

Enrollment must preserve that rule when consuming or realigning shifter behavior.

### 5. Grading windows are now term-scoped

Registrar now supports per-term grading windows in:

```sql
grading_term_windows
```

Important behavior:

- grade sheets resolve grading windows from the class section’s `term_id`
- if a term has no specific grading window row, registrar falls back to legacy global settings
- historical grade/load data must remain tied to the original section/enlistment term

Enrollment should not assume that the newest active global term’s grading window applies to every class or historical record.

### 6. Registrar term policies are now configurable instead of hardcoded

Registrar now stores and uses configurable academic-term-adjacent policies, including:

- `ACCOUNTING_BLOCK_THRESHOLD`
- `ADMISSION_MIN_PAYMENT`
- `DOWNPAYMENT_THRESHOLD`
- term-scoped `academic_term_policies.inc_expiration_date`

For enrollment-side realignment, the most important rule is:

- `INC` expiration is term-scoped and no longer something enrollment should guess from a hardcoded rule
- expired INC processing uses registrar-final outcome semantics, not raw `grades.remarks` alone

### 7. Registrar-final grade outcomes are now sticky

Registrar now distinguishes between recomputable faculty-side grade state and authoritative registrar-final outcomes.

Grades may now store registrar-final values in the `grades` table using:

- `registrar_final_grade`
- `registrar_final_remarks`
- `grade_lock_status`
- `grade_lock_reason`
- `registrar_finalized_at`

Finalized registrar behaviors already implemented:

- overdue `INC` can be expired to registrar-final `Failed`
- approved grade changes write registrar-final outcomes
- locked registrar-final outcomes should not be silently overwritten by later faculty-side recomputation or blank component refreshes
- raw `grades.remarks = 'INC'` must not override `registrar_final_remarks = 'Failed'`

Enrollment should treat these registrar-final fields as authoritative whenever they are present and locked.

### 8. Scholarship eligibility and granting are registrar-owned

Registrar now owns academic scholarship policy and granting.

Implemented registrar behavior:

- `/admin/scholarships` evaluates term scholarship candidates from official `grades`
- `/admin/scholarships` maintains the manual scholarship type catalog
- eligibility uses `COALESCE(registrar_final_grade, semestral_grade)`
- eligibility uses `COALESCE(registrar_final_remarks, remarks)`
- registrar-final failed or INC outcomes are honored before raw faculty-side remarks
- registrar grants/revokes by updating the canonical `students` scholarship fields
- the old student-manager scholarship card now posts `student_number`, not internal `user_id`

Canonical scholarship fields for enrollment/finance consumers:

```sql
students.scholarship_approved
students.scholarship_type
students.scholarship_amount
students.discount_percentage
```

Important rule:

- `scholarship_approved = 1` is required before any discount should be applied
- `scholarship_type = 'NONE'` or `scholarship_approved = 0` means no active scholarship
- enrollment should not infer active scholarship from non-null `scholarship_type` alone

Manual scholarship type catalog:

```sql
scholarship_types.classification
scholarship_types.display_name
scholarship_types.discount_mode
scholarship_types.default_discount_percentage
scholarship_types.default_scholarship_amount
scholarship_types.is_internal
scholarship_types.requires_id
scholarship_types.is_active
```

Discount modes:

- `PERCENT`: registrar stores the configured rate in `students.discount_percentage`
- `FLAT`: registrar stores the peso amount in `students.scholarship_amount`
- `FULL`: registrar stores a 100% discount

Enrollment does not need the catalog to calculate active student discounts; it can continue consuming the canonical `students` scholarship fields. The catalog is mainly for registrar UI labels/defaults.

Configurable scholarship policy keys in `system_settings`:

- `SCHOLARSHIP_MAX_GWA`
- `SCHOLARSHIP_MAX_INDIVIDUAL_GRADE`
- `SCHOLARSHIP_DEFAULT_DISCOUNT_PERCENT`
- `SCHOLARSHIP_MIN_COMPLETED_SUBJECTS`
- `SCHOLARSHIP_DISQUALIFY_INC`
- `SCHOLARSHIP_DISQUALIFY_FAILED`

Enrollment should not duplicate scholarship eligibility calculations unless explicitly required. If it must display scholarship eligibility, it should mirror registrar logic and prefer registrar-final grade outcomes.

## Finalized Registrar DB Objects Enrollment Should Expect

The registrar SQL source-of-truth files have been aligned so fresh builds and legacy patch runs create the same finalized objects:

- `db/fix`
- `db/eacdb_cross_system_schema.sql`

Enrollment-side code may now expect these objects/columns to exist after a clean registrar database build or after running the cross-system schema patch:

- `student_curriculum_assignments`
- `grading_term_windows`
- `academic_term_policies.inc_expiration_date`
- `grades.registrar_final_grade`
- `grades.registrar_final_remarks`
- `grades.grade_lock_status`
- `grades.grade_lock_reason`
- `grades.registrar_finalized_at`
- `grade_change_requests.request_type`
- `grade_change_requests.requested_prelim`
- `grade_change_requests.requested_midterm`
- `grade_change_requests.requested_finals`
- `grade_change_requests.applied_action`
- `grade_change_requests.approved_at`
- expanded `scholarship_types` catalog columns listed above

Default policy keys seeded by registrar:

- `ACCOUNTING_BLOCK_THRESHOLD`
- `ADMISSION_MIN_PAYMENT`
- `DOWNPAYMENT_THRESHOLD`
- `SCHOLARSHIP_MAX_GWA`
- `SCHOLARSHIP_MAX_INDIVIDUAL_GRADE`
- `SCHOLARSHIP_DEFAULT_DISCOUNT_PERCENT`
- `SCHOLARSHIP_MIN_COMPLETED_SUBJECTS`
- `SCHOLARSHIP_DISQUALIFY_INC`
- `SCHOLARSHIP_DISQUALIFY_FAILED`

## Enrollment-Side Contract To Follow

The next enrollment-side pass should align to these registrar rules.

### A. Term resolution contract

Enrollment should prefer student-resolved current term first, not the registrar active term by default.

Expected rule:

- prefer a student-aware resolver such as `resolveTermIdForStudent(student)`
- use registrar active term only as fallback when the student cannot be mapped
- avoid loose string matching where real `term_id` is available

### B. Current-term screens must stay term-scoped

Current-term enrollment screens should:

- show only the student’s resolved current-term load
- show only current-term available offerings for that same resolved term
- avoid falling back to all-history behavior when no term resolves

Historical rows must not appear on current-term management screens.

### C. Duplicate blocking must be same-term, not all-history

Enrollment should block duplicate enlistment only within the same resolved term.

A prior-term enrollment for the same course must not suppress a legitimate current-term enrollment.

### D. Continuing students must use assigned curriculum

Enrollment recommendation, deficiency, and curriculum-driven subject logic should:

- use `student_curriculum_assignments.is_current = 1` for continuing students
- use program active/default curriculum only for new entrants or default setup flows

### E. Program shifts must preserve curriculum assignment semantics

Enrollment must not implement shifts by changing only:

```sql
students.program_code
```

A valid shift must also result in a destination-program curriculum assignment that matches registrar expectations.

### F. History must remain term-stable

Enrollment should preserve:

- prior-term section rows
- prior-term enlistment rows
- prior-term grade rows

Term transition must not rewrite historical grades or move old loads into the new active term.

### G. Registrar-final grades should win when present

If enrollment reads grades for prerequisite, history, or future academic decisions, it should prefer:

- `registrar_final_grade`
- `registrar_final_remarks`

over raw recomputed faculty values when the row is registrar-locked.

This is especially important for:

- expired `INC`
- approved grade changes
- any downstream prerequisite or academic-standing logic

### H. Scholarship discounts must respect approval state

Enrollment-side assessment and cashier pages should apply scholarship discounts only when:

- `students.scholarship_approved = 1`
- `students.scholarship_type` is not null and not `NONE`

For academic scholarships, enrollment should not attempt to auto-award. Registrar is the awarding authority; enrollment only consumes the final approved scholarship state.

## Enrollment-Side Work Already Completed

One enrollment-side realignment pass was already completed and documented separately. Its completed outcomes were:

- current-term subject management now resolves the student’s current term
- current-term load no longer leaks historical enlistments
- regular new-student auto-enlist is term-scoped
- offering loaders no longer fall back to all-history behavior when no term resolves
- manual add now validates selected section term against the student’s resolved current term

That completed analysis and implementation record is documented in:

- `docs/handoff/legacy-capss/03-agent-dev/ENROLLMENT_REALIGNMENT_ANALYSIS_HANDOFF.md`

## Known Open Enrollment Question That Is Not Yet Resolved

The following item is still a business-rule or section-setup question and should not be treated as a registrar failure:

- `UCP2 42` conflicts with `UOJT 42`
- known overlap includes Monday `10:00-10:30`

This still needs an enrollment-side decision:

- keep the conflict as intended policy
- adjust section setup
- add a manual/exempt OJT flow

This is not part of the registrar transition fix itself.

## Recommended Starting Point For The Next Enrollment Agent

1. Start from this consolidated file.
2. Cross-check against:
   - `docs/handoff/legacy-capss/03-agent-dev/ENROLLMENT_REALIGNMENT_ANALYSIS_HANDOFF.md`
   - `docs/handoff/legacy-capss/03-agent-dev/ENROLLMENT_REALIGNMENT_CURRICULUM_TERM_GRADING_HANDOFF.md`
3. Audit any enrollment path that:
   - resolves current term
   - recommends subjects from curriculum
   - handles shifters
   - reads grade outcomes for academic decisions
4. Preserve registrar as the source of truth for:
   - active term state
   - student curriculum assignment
   - term-scoped grading windows
   - registrar-final grade outcomes

## Reading Order For The Next Enrollment Agent

If you only hand over one file, hand over this file.

Use the rest only as supporting reference, in this order:

1. Primary handoff:
   - `docs/handoff/legacy-capss/03-agent-dev/ENROLLMENT_REALIGNMENT_CONSOLIDATED_HANDOFF.md`
2. First supporting reference:
   - `docs/handoff/legacy-capss/03-agent-dev/ENROLLMENT_REALIGNMENT_ANALYSIS_HANDOFF.md`
   - use this for the earlier completed enrollment-side term-scoping implementation details
3. Second supporting reference:
   - `docs/handoff/legacy-capss/03-agent-dev/ENROLLMENT_REALIGNMENT_CURRICULUM_TERM_GRADING_HANDOFF.md`
   - use this for student-curriculum, shifter, and grading-term assumptions that registrar already finalized
4. Optional background only:
   - `docs/handoff/legacy-capss/03-agent-dev/ENROLLMENT_REALIGNMENT_BRIEF.md`
   - `docs/handoff/legacy-capss/03-agent-dev/REGISTRAR_TERM_SYSTEM_IMPLEMENTATION_HANDOFF.md`

The agent does not need to start from the brief unless they want historical context.
The agent also does not need to reread registrar implementation history before understanding the current contract.

## What To Tell The Next Enrollment Agent

Pass this file and tell them:

- this is the consolidated source of truth
- everything in this file is already finalized on the registrar side
- implement against the finalized registrar grading-change, reopen, and scholarship contracts in this file
- use the supporting references only when deeper implementation detail is needed

## Files To Ignore Unless Specifically Needed

These are not the best starting point for the next enrollment pass:

- legacy handoff logs in `docs/handoff/legacy-capss/07-legacy`
- partial historical notes that were superseded by this consolidated file

They may still be useful for audit trail, but they are not the working contract.

## Short Version

For enrollment, the finalized registrar contract so far is:

- term transition is real and verified
- exact term fees matter
- current-term flows must be truly term-scoped
- continuing students stay on assigned curriculum
- shifters need destination curriculum assignment
- grading windows are term-scoped
- `INC` expiry is term-scoped
- registrar-final locked grades are authoritative
- scholarship discounts require `scholarship_approved = 1`
- academic scholarship eligibility/granting is registrar-owned
- manual scholarship types are configurable through `scholarship_types`
