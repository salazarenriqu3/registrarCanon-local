# Enrollment Realignment Handoff: Academic Term, Curriculum, Shifters, and Grading

Registrar is the source of truth for this handoff. Do not infer enrollment behavior from the newest active curriculum alone.

## Registrar Rules Now In Force

1. Academic term is global.

The active term is still resolved from `academic_terms` / `system_settings.CURRENT_ACADEMIC_TERM`. Term transition advances eligible students and forwards prior balances, but it must not change a student's curriculum assignment.

2. Curriculum is assigned per student.

Registrar now tracks current student catalog assignment in:

```sql
student_curriculum_assignments
```

Important columns:

- `student_number`
- `curriculum_id`
- `program_code`
- `assignment_type`
- `is_current`
- `reason`
- `assigned_at`

Enrollment should treat `is_current = 1` as the student's active catalog. If no assignment exists for legacy data, registrar may backfill from the student's program default curriculum.

3. Program active curriculum is only the default for new entrants.

`curriculum_templates.is_active = 1` means "default catalog for new students / default destination catalog", not "replace every continuing student."

4. Continuing students stay on their assigned curriculum.

Continuing students should keep using their assigned `curriculum_id` even if the program publishes a newer active curriculum for a later academic year.

5. Program shifters need an explicit destination curriculum.

Registrar program shift now assigns a destination curriculum. If no specific curriculum is selected, registrar uses the target program's active/default curriculum.

Enrollment must not shift a student by updating only `program_code`. A shift must also result in a current destination-program curriculum assignment.

6. Grading is term-scoped through sections.

Grades remain tied to `grades.section_id`, and sections are tied to `class_sections.term_id`. Enrollment should preserve historical section/enlistment rows by term. Do not rewrite prior-term grade/load rows when the global term changes.

7. Grading windows are now term-scoped with global fallback.

Registrar now stores per-term grading calendar rows in:

```sql
grading_term_windows
```

Important columns:

- `term_id`
- `grading_period`
- `start_date`
- `end_date`
- `override_status`

If a selected term has no row, registrar falls back to legacy `system_settings` keys (`PRELIM_START`, `PRELIM_END`, etc.). Grade sheets resolve windows from the class section's `term_id`, not simply from the newest active/global term.

## Enrollment-Side Realignment Needed

Enrollment should audit and update these assumptions:

- Subject/block recommendations for a continuing student should read the student's current `student_curriculum_assignments.curriculum_id`, not just the active program curriculum.
- New entrant subject recommendations may use the active/default curriculum for the student's program.
- Program shift flows must require or derive a destination curriculum assignment.
- Manual/irregular subject selection may browse active/default offering catalogs, but the student's own program recommendations should prefer the assigned curriculum.
- Graduation/deficiency checks must use the assigned curriculum.
- Grade and load history must remain term-scoped through section/enlistment rows.
- Term transition must not delete or rewrite historical grades/enlistments.
- Any enrollment UI that displays grading availability should resolve by the section/enlistment term and should not assume the current global term's grading window applies to historical sections.

## Registrar Files Changed

- `src/main/java/com/iuims/registrar/service/StudentCurriculumService.java`
- `src/main/java/com/iuims/registrar/service/FinanceAdmissionService.java`
- `src/main/java/com/iuims/registrar/service/JaypeeIntegrationService.java`
- `src/main/java/com/iuims/registrar/service/ScholarEnrollmentService.java`
- `src/main/java/com/iuims/registrar/service/AcademicGradingService.java`
- `src/main/java/com/iuims/registrar/controller/EnrollmentController.java`
- `src/main/java/com/iuims/registrar/controller/AcademicController.java`
- `src/main/resources/templates/admin_student_manager.html`
- `src/main/resources/templates/admin_settings.html`
- `db/fix`

## Expected Enrollment Test Cases

1. Continuing student remains on old curriculum after new curriculum becomes active.

Setup:
- Student has `student_curriculum_assignments.is_current = 1` pointing to an older curriculum.
- Program has a newer `curriculum_templates.is_active = 1`.

Expected:
- Enrollment recommendations use the student's assigned old curriculum.

2. New entrant receives current program default curriculum.

Expected:
- Newly admitted student gets a current assignment to the program active/default curriculum.

3. Program shifter receives destination curriculum.

Expected:
- Shift updates program and creates a current destination-program curriculum assignment.
- Prior grades/load history remains under old term/program context.

4. Grading/history remains term-stable.

Expected:
- Activating a new term does not move old grades to the new term.
- Prior section/enlistment rows remain available as history.
- A prior-term class/grade sheet uses that class section's grading window, not the current active term's grading window.
- A term without specific grading windows uses legacy/global grading settings as fallback.

## Caution

Enrollment should not assume:

```sql
JOIN curriculum_templates ct ON ct.program_id = p.program_id AND ct.is_active = 1
```

for continuing-student curriculum decisions. That pattern is only safe for new entrants, default setup, or catalog browsing where the user is not asking for a student's assigned course map.
