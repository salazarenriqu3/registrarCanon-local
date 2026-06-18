# Database Migration Sign-Off

Use this template when promoting schema changes from Registrar dev to shared/staging databases.

## Release

| Field | Value |
|-------|-------|
| Release / sprint | |
| Date | |
| Environment | dev / staging / prod |
| Applied by | |

## Schema changes

| Object | Change type | Script / auto-migrate | Verified |
|--------|-------------|----------------------|----------|
| `student_program_shift_requests` | CREATE TABLE | `ProgramShiftRequestService.ensureSchema()` | ☐ |
| `grading_schemes` | CREATE TABLE | `DatabaseSetupService` / `GradingSchemeService` | ☐ |
| `student_holds` | CREATE TABLE | `DatabaseSetupService` / `StudentHoldService` | ☐ |
| `academic_term_policies.midterm_exam_date` | ADD COLUMN | `DatabaseSetupService` | ☐ |
| `courses.course_type` | ADD COLUMN | `DatabaseSetupService` | ☐ |
| `class_sections.petition_min_headcount` | ADD COLUMN | `DatabaseSetupService` | ☐ |
| `system_settings` enrollment period keys | SEED | `DatabaseSetupService` | ☐ |
| `enrollment_settings.drop_penalty_first_week_percent` | SEED | `FinancePolicyService` | ☐ |

## Verification checklist

- [ ] Application starts cleanly (`mvn spring-boot:run` or deployed instance)
- [ ] `mvn test -Dtest=!ModulithTests` passes
- [ ] Sample student: print Registration Form respects downpayment gate
- [ ] Program shift request creates row and appears in Dean/Registrar queues
- [ ] Student hold blocks portal my-load / my-grades
- [ ] Finance Policy saves enrollment close date and blocks enlistment after close

## Rollback notes

| Change | Rollback action |
|--------|-----------------|
| New tables | `DROP TABLE` only if no production data (otherwise leave and disable feature flag) |
| New columns | Columns are nullable/defaulted; rollback optional |

## Sign-off

| Role | Name | Signature / date |
|------|------|------------------|
| Developer | | |
| DBA | | |
| Registrar lead | | |
