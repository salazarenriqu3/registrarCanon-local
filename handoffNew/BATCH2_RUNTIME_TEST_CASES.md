# Batch 2 Runtime Test Cases

Last updated: 2026-06-06

## Purpose

This note captures the controlled runtime pack used to verify the active Batch 2 enlistment lifecycle behavior.

The temporary records used the `B2TEST` prefix and were removed after verification.

## Test Data Shape

- `B2TEST-STAGED`: staged-only student with one `STAGED` enlistment in `B2TEST-SEC`
- `B2TEST-COMMIT`: enrolled student with one `COMMITTED` enlistment in `B2TEST-SEC`
- `B2TEST-WAIT`: waitlist student promoted through enrollment-side registrar force-enroll into `B2TEST-WL`
- `B2TEST-FAC`: faculty account assigned to both controlled sections
- `B2TEST-REG`: registrar active class scheduling section with one `STAGED` row and one `COMMITTED` row

## Verified Cases

- Cashier staging showed the staged-only student and staged subject.
- Official ledger ignored the staged-only subject and showed no finalized assessment.
- Enrollment-side registrar section monitor counted only committed rows.
- Faculty dashboard counted only committed rows.
- Faculty section roster listed the committed student and did not list the staged-only student.
- Waitlist force-enroll created a `COMMITTED` enlistment instead of relying on a default or null status.
- Waitlist force-enroll handled the live text-shaped `student_waitlist.student_id` value.
- Section monitor counted the force-enrolled waitlist row after promotion.
- Registrar active class scheduling rendered `B2TEST-REG` as `1 / 40 enrolled` with one staged row and one committed row.
- Registrar active class scheduling rendered successfully after replacing unsafe Thymeleaf event-handler string expressions with `data-*` attributes.

## Cleanup

All temporary `B2TEST` rows were removed from:

- `student_enlistments`
- `student_waitlist`
- `class_sections`
- `courses`
- `students`
- `sys_users`
- `faculty`
- registrar `B2TEST-REG` test rows in `student_enlistments`, `class_sections`, and `courses`

Cleanup verification returned zero rows for every `B2TEST` bucket.

## Batch 2 Reading

Active enrollment-side behavior and active registrar scheduler/class-count behavior passed these controlled cases.

Deprecated registrar enrollment/payment screens remain intentionally outside this active Batch 2 acceptance scope.
