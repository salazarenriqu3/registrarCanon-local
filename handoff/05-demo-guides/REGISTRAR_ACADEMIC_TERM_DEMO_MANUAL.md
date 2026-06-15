# Registrar Academic Term Demo Manual

Date: 2026-06-04

This manual demonstrates the finalized registrar-side academic term business logic. It is designed for a live QA run, panel demo, or handoff validation before enrollment-side realignment work continues.

Use this guide after the registrar app has been rebuilt and redeployed.

## Demo Scope

This guide covers the registrar-side features that are now finalized:

- Active term readiness and safe global term transition
- Exact-term program fee setup and readiness clearing
- Student curriculum assignment and program shift behavior
- Term-scoped grading windows
- Term-scoped INC expiration
- Registrar-final grade outcomes and grade-change approvals
- Academic scholarship eligibility
- Manual scholarship type catalog and scholarship granting
- Enrollment-side handoff validation points

This guide does not require enrollment-side code changes. Enrollment behavior should be tested separately using the consolidated enrollment handoff after registrar validation passes.

## Prerequisites

Use these assumptions for the demo:

- Registrar is running at `http://localhost:8083/registrar`
- Registrar admin login is available, commonly `admin / 1234`
- Database is `eacdb`
- Current verified active term is `A.Y. 2027-2028 - 2nd Semester`
- Active term id is expected to be `15`
- Registrar has already been rebuilt after the latest changes

Recommended verification before starting:

```sql
SELECT term_id, term_code, term_name, status, is_active
FROM academic_terms
ORDER BY term_id;

SELECT setting_key, setting_value
FROM system_settings
WHERE setting_key IN (
  'CURRENT_ACADEMIC_TERM',
  'ACCOUNTING_BLOCK_THRESHOLD',
  'ADMISSION_MIN_PAYMENT',
  'DOWNPAYMENT_THRESHOLD',
  'SCHOLARSHIP_MAX_GWA',
  'SCHOLARSHIP_MAX_INDIVIDUAL_GRADE',
  'SCHOLARSHIP_DEFAULT_DISCOUNT_PERCENT',
  'SCHOLARSHIP_MIN_COMPLETED_SUBJECTS',
  'SCHOLARSHIP_DISQUALIFY_INC',
  'SCHOLARSHIP_DISQUALIFY_FAILED'
)
ORDER BY setting_key;
```

Pass condition:

- `academic_terms.term_id = 15` is active
- `system_settings.CURRENT_ACADEMIC_TERM` points to the active registrar term
- The policy keys above exist

## Part 1: Active Term Readiness

Purpose:

This proves that the registrar does not blindly advance the whole school into a new term. The target term must first be operationally ready.

Business explanation:

The active term readiness panel checks whether the selected term has the fee and curriculum setup needed for registrar and enrollment operations. A term with missing fee scopes or fallback-only fee rows is not safe to operate because student billing can become inconsistent.

Steps:

1. Open `http://localhost:8083/registrar/admin/settings`.
2. Locate `Active Term Readiness`.
3. Confirm the selected/current term is `A.Y. 2027-2028 - 2nd Semester`.
4. Review the readiness cards:
5. Confirm `Missing fee scopes` is `0`.
6. Confirm `Fallback fee scopes` is `0`.
7. Confirm the status badge says `Ready`.

Expected result:

- The readiness panel is green or marked `Ready`.
- The term transition button is enabled only when readiness is clear.

Fail conditions:

- `Missing fee scopes` is greater than `0`.
- `Fallback fee scopes` is greater than `0`.
- Status says `Needs review`.
- Transition button is disabled.

What to do if it fails:

- Click `Review term fees`.
- Use the Program Fees screen to prepare/copy exact term fees.
- Return to System Settings and confirm readiness again.

## Part 2: Program Fees And Exact-Term Fee Setup

Purpose:

This proves that the registrar uses exact term fee rows for the selected academic term instead of silently relying on old fallback fee rows.

Business explanation:

Program fees are term-scoped. A fee from an older term can be useful as a source/template, but operating a new term should use exact rows for that term. This avoids future surprises where changing old fees affects a new active term.

Steps:

1. Open `http://localhost:8083/registrar/admin/term-fees?termId=15`.
2. Confirm the selected academic term is `A.Y. 2027-2028 - 2nd Semester`.
3. Click `Prepare term fees` if the page shows missing scopes.
4. If imported templates are available, use the copy/import action to seed program fee templates.
5. Select a program, year level, and semester.
6. Click `Load`.
7. Confirm fee rows display as `Exact term`.
8. Save fees if any missing or blank fee rows were manually filled.

Expected result:

- Program fee rows load for term `15`.
- Source badges should show `Exact term`.
- Readiness should eventually show `Missing fee scopes = 0` and `Fallback fee scopes = 0`.

Pass/fail quick check:

```sql
SELECT COUNT(*) AS fallback_general_rows
FROM program_general_fees
WHERE term_id IS NULL;

SELECT COUNT(*) AS exact_term_general_rows
FROM program_general_fees
WHERE term_id = 15;

SELECT COUNT(*) AS exact_term_specific_rows
FROM program_specific_fees
WHERE term_id = 15;
```

Interpretation:

- Fallback rows may still exist as historical/template rows.
- Exact term rows for `term_id = 15` must exist.
- Readiness, not this raw count alone, is the authoritative UI check.

## Part 3: Safe Global Academic Term Transition

Purpose:

This proves that the global academic term transition is guarded, real, and auditable.

Business explanation:

Transitioning the global term advances eligible students and moves unpaid prior-term balances forward. This operation affects registrar, cashier, and enrollment. It must not be available unless the target term is ready.

Steps:

1. Open `System Settings`.
2. Locate `Global Academic Term Transition`.
3. Select `A.Y. 2027-2028 - 2nd Semester`.
4. Confirm helper text says the selected term is ready to transition.
5. Click `Transition Term` only during a controlled test or demo.
6. Confirm the success message appears.

Expected result:

- Success banner says the global academic term was updated.
- Active term readiness remains `Ready`.
- Students are advanced to the selected term.
- Forwarded balances are rolled into the new term context.

Safety note:

This action cannot be undone from the UI. Do not click it repeatedly on a production-like database unless you intentionally want to advance the term again.

## Part 4: Student Curriculum Assignment

Purpose:

This proves continuing students keep the curriculum they were assigned to, even if the program's active curriculum changes later.

Business explanation:

The active curriculum of a program is only the default for new entrants or default assignment. Continuing students should finish the curriculum they entered under. This prevents an old student from suddenly being forced into a newer curriculum.

Key table:

```sql
student_curriculum_assignments
```

Steps:

1. Open `Student Manager`.
2. Search a student such as `2026-0002` or another known test student.
3. Locate the `Current Assigned Curriculum` panel.
4. Confirm the assigned curriculum is shown.
5. Open the program shift panel.
6. Select a target program.
7. Choose either `Use target program active curriculum` or a specific destination curriculum.
8. Pick year level and semester.
9. Add a reason if desired.
10. Click `Apply Program Shift`.

Expected result:

- The student's `program_code` changes.
- A current row is created in `student_curriculum_assignments`.
- Prior curriculum assignment rows are no longer current.
- Academic history remains historical and is not rewritten.

Database verification:

```sql
SELECT assignment_id, student_number, curriculum_id, program_code,
       assignment_type, reason, is_current, assigned_at
FROM student_curriculum_assignments
WHERE student_number = '2026-0002'
ORDER BY assignment_id DESC;
```

Pass condition:

- Latest row has `is_current = 1`.
- Latest row matches the destination program.
- Older rows, if any, have `is_current = 0`.

## Part 5: Term-Scoped Grading Windows

Purpose:

This proves grading open/closed status comes from the class section term, not just the global active term.

Business explanation:

A professor's grade sheet belongs to a class section, and that class section belongs to a term. The grading window should be resolved from that term. This protects historical classes from being reopened or closed just because the registrar active term changed.

Steps:

1. Open `System Settings`.
2. Locate `Grading Calendar & Overrides`.
3. Select `A.Y. 2027-2028 - 2nd Semester`.
4. Set Prelim, Midterm, and Finals start/end dates.
5. Keep manual override as `Auto (Follow Dates)` unless you need to force open/closed behavior.
6. Click `Save Matrix Configurations`.
7. Log in as a faculty/professor user.
8. Open a grade encoding sheet for a class in that term.
9. Confirm each grading period shows `OPEN` or `CLOSED` based on the configured dates.

Expected result:

- The settings save successfully.
- Grade sheet period badges match the selected term's configured windows.
- Inputs are enabled only when the relevant period is open or when an approved exception exists.

Database verification:

```sql
SELECT term_id, grading_period, start_date, end_date, override_status
FROM grading_term_windows
WHERE term_id = 15
ORDER BY grading_period;
```

## Part 6: Term-Scoped INC Expiration

Purpose:

This proves the registrar can set the exact expiration date for INC grades per term, then convert overdue INC grades into official Failed outcomes.

Business explanation:

INC should not remain open forever. The registrar now stores the expiration policy by term. When the deadline has passed, eligible INC rows can be finalized as Failed. The final Failed outcome is sticky and must not revert to INC during later recomputation.

Steps:

1. Open `System Settings`.
2. Select the grading term.
3. Set `INC Expiration Date`.
4. Click `Save Matrix Configurations`.
5. Click `Expire Due INCs`.
6. Confirm the blue message showing how many due INC grades were expired.
7. Open the related grade sheet.
8. Confirm expired rows show `Failed`.
9. Refresh the grade sheet.
10. Confirm the rows still show `Failed`.

Expected result:

- Due INC grades are converted to `Failed`.
- `registrar_final_grade` becomes `5.00`.
- `registrar_final_remarks` becomes `Failed`.
- `grade_lock_status` becomes `LOCKED`.
- `grade_lock_reason` becomes `INC_EXPIRED`.

Database verification:

```sql
SELECT g.id, g.student_id, g.remarks, g.semestral_grade,
       g.registrar_final_remarks, g.registrar_final_grade,
       g.grade_lock_status, g.grade_lock_reason
FROM grades g
JOIN class_sections cs ON cs.section_id = g.section_id
WHERE cs.term_id = 15
ORDER BY g.id DESC;
```

Pass condition:

- Expired INC rows have registrar-final `Failed`.
- A raw `remarks = 'INC'` must not override a registrar-final `Failed`.

## Part 7: Grade Encoding And Registrar Approval

Purpose:

This proves faculty can submit grades, registrar can approve corrections, and registrar-final outcomes become authoritative.

Business explanation:

Faculty-side component grades can be recomputed. Registrar-approved outcomes are different: they represent official record state. Once locked, they should win over later faculty-side recalculation unless the registrar explicitly reopens the row for edit.

Steps for faculty submission:

1. Log in as professor/faculty.
2. Open the grade encoding sheet for a submitted class.
3. Enter grades for Prelim, Midterm, and Finals when periods are open.
4. Submit the class to Registrar.
5. Confirm the success banner appears.

Steps for registrar approval:

1. Log in as registrar admin.
2. Open `Grade Approvals`.
3. Locate `Pending Class Grade Submissions`.
4. Open or approve the submitted class as required by the current UI flow.
5. For correction testing, return to the grade sheet and click `Request Change`.
6. Submit a grade-change request.
7. Return to registrar admin approvals.
8. Approve the request.
9. Refresh the grade sheet.

Expected result:

- Submitted classes appear in registrar approvals.
- Approved grade changes update official display values.
- Registrar-final fields are populated when the action creates an official outcome.
- Locked failed rows remain failed even if component grades later become blank or incomplete.

Important behavior:

- A normal grade-change request may directly change the official point grade.
- A reopen-for-edit flow unlocks only the specific row being corrected.
- Other locked rows must stay locked and authoritative.

Database verification:

```sql
SELECT request_id, grade_id, student_name, course_code, request_type,
       requested_grade, requested_prelim, requested_midterm, requested_finals,
       status, applied_action, approved_at
FROM grade_change_requests
ORDER BY request_id DESC;

SELECT id, student_id, prelim, midterm, final_grade,
       semestral_grade, remarks,
       registrar_final_grade, registrar_final_remarks,
       grade_lock_status, grade_lock_reason
FROM grades
ORDER BY id DESC;
```

## Part 8: Academic Scholarship Policy

Purpose:

This proves registrar can evaluate students for academic scholarship based on official grades and configurable policy.

Business explanation:

Academic scholarship eligibility should be registrar-owned because it depends on official grade outcomes. The system uses registrar-final grade values first, then falls back to raw semestral grade values only when no registrar-final value exists.

Steps:

1. Open `http://localhost:8083/registrar/admin/scholarships`.
2. Select the academic term.
3. Set `Max GWA`.
4. Set `Max Grade`.
5. Set `Default Discount %`.
6. Set `Min Subjects`.
7. Toggle `Disqualify INC` and `Disqualify Failed`.
8. Click `Save Scholarship Policy`.
9. Review `Term Scholarship Review`.

Expected result:

- Eligible students show an `Eligible` badge.
- Ineligible students show a clear reason.
- Failed and INC outcomes use registrar-final remarks first.
- Grant button appears only for eligible students.

Database policy verification:

```sql
SELECT setting_key, setting_value
FROM system_settings
WHERE setting_key LIKE 'SCHOLARSHIP_%'
ORDER BY setting_key;
```

## Part 9: Manual Scholarship Types And Granting

Purpose:

This proves non-academic scholarships such as Barangay, LGU, Athlete, Employee Dependent, or Other can be configured and granted manually.

Business explanation:

Not all scholarship types are grade-based. Some are external or administrative grants. Registrar controls the catalog and may configure whether a type is percent-based, flat-amount, or full-discount.

Scholarship discount modes:

- `PERCENT`: stores a rate in `students.discount_percentage`
- `FLAT`: stores a peso amount in `students.scholarship_amount`
- `FULL`: stores a 100 percent discount

Steps to configure scholarship types:

1. Open `Scholarships`.
2. Locate the manual scholarship type catalog section.
3. Add or edit a scholarship type.
4. Example: create `Barangay Scholar`.
5. Choose `PERCENT` and enter `50`.
6. Save the type.
7. Confirm it appears in the active scholarship type list.

Steps to grant a scholarship:

1. Open `Student Manager`.
2. Search a student.
3. Locate the scholarship or program/finance panel where manual grant is available.
4. Select a scholarship type.
5. Confirm the default percent or amount loads.
6. Approve/grant the scholarship.
7. Refresh the student page.

Expected result:

- `students.scholarship_approved = 1`
- `students.scholarship_type` is set to the selected classification
- `students.discount_percentage` is set for percent/full discounts
- `students.scholarship_amount` is set for flat discounts

Database verification:

```sql
SELECT classification, display_name, discount_mode,
       default_discount_percentage, default_scholarship_amount,
       is_internal, requires_id, is_active
FROM scholarship_types
ORDER BY display_name, classification;

SELECT student_number, scholarship_approved, scholarship_type,
       scholarship_amount, discount_percentage
FROM students
WHERE scholarship_approved = 1
ORDER BY student_number;
```

Pass condition:

- Enrollment and cashier should apply a scholarship discount only when `scholarship_approved = 1`.
- `scholarship_type = 'NONE'` or `scholarship_approved = 0` means no active scholarship.

## Part 10: Final Registrar Smoke Test Checklist

Run this checklist after code changes or before handing the database to the enrollment agent.

1. System Settings opens without error.
2. Active Term Readiness shows `Ready`.
3. Term `15` has `Missing fee scopes = 0`.
4. Term `15` has `Fallback fee scopes = 0`.
5. Program Fees page loads with `termId=15`.
6. Grading windows save successfully.
7. INC expiration date saves successfully.
8. `Expire Due INCs` returns a clear count message.
9. Grade sheet displays registrar-final Failed rows as Failed after refresh.
10. Grade-change approval appears and can be approved.
11. Academic scholarship policy saves.
12. Manual scholarship type can be added or edited.
13. Scholarship grant/revoke updates canonical `students` fields.
14. Student Manager program shift creates a current curriculum assignment.
15. Consolidated enrollment handoff exists and is updated.

## Enrollment Agent Handoff

After this registrar demo passes, give the enrollment agent this file:

```text
C:\Users\admin\Downloads\6126\projects\registrar\handoff\03-agent-dev\ENROLLMENT_REALIGNMENT_CONSOLIDATED_HANDOFF.md
```

Tell the enrollment agent:

- Registrar is the source of truth for active term, term fees, grading windows, INC expiration, registrar-final grades, curriculum assignment, and scholarship granting.
- Enrollment should consume registrar-final fields before raw grade fields.
- Enrollment should use student curriculum assignment for continuing students.
- Enrollment should apply scholarships only when `students.scholarship_approved = 1`.
- Enrollment should not duplicate academic scholarship awarding unless explicitly required.

## Troubleshooting

Symptom: System Settings save returns `404 /admin/save-settings`

Fix:

- Rebuild and redeploy registrar.
- Confirm settings form posts to the registrar context path.

Symptom: INC expiration says `Expired 0`, but the grade still looks INC.

Fix:

- Confirm the selected grading term matches the class section `term_id`.
- Confirm `INC_EXPIRATION_DATE` is today or earlier.
- Check whether `registrar_final_remarks` is already `Failed`; if yes, this is already finalized and should not expire again.

Symptom: Failed row reverts to INC after editing another row.

Fix:

- Confirm `grade_lock_status = 'LOCKED'`.
- Confirm `registrar_final_remarks = 'Failed'`.
- Use the latest registrar build with the registrar-final outcome fix.

Symptom: Scholarship discount does not apply.

Fix:

- Confirm `students.scholarship_approved = 1`.
- Confirm `students.scholarship_type != 'NONE'`.
- Confirm percent scholarships use `discount_percentage`.
- Confirm flat scholarships use `scholarship_amount`.

Symptom: Active term readiness shows missing fees.

Fix:

- Open Program Fees for the selected `termId`.
- Run `Prepare term fees`.
- Copy imported templates if available.
- Manually fill missing tuition or RLE rows.
- Return to System Settings and recheck readiness.

## Short Demo Script

Use this quick version when presenting live:

1. Show System Settings and the active term readiness badge.
2. Open Program Fees and show `Exact term` fee rows.
3. Show the global term transition panel and explain the readiness gate.
4. Open Student Manager and show current curriculum assignment.
5. Demonstrate or explain a program shift creating a destination curriculum assignment.
6. Open Grading Calendar and show term-scoped grading windows.
7. Open a grade sheet and show period `OPEN` or `CLOSED` badges.
8. Show an expired INC row finalized as `Failed`.
9. Show Grade Approvals and explain registrar-final locking.
10. Open Scholarships, show academic policy, eligibility review, and manual scholarship types.
11. End by showing the consolidated enrollment handoff file.

