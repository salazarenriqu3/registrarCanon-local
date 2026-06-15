# Admission Handoff: Irregular Pre-Registration Snapshot

Date: 2026-06-14  
Updated: 2026-06-15
Owner app: Registrar
Consumer app/team: Admission

## Summary

Registrar now provides the irregular applicant pre-registration snapshot needed by Admission before a new irregular/transferee applicant can be marked qualified/admitted.

The editable workflow is no longer on the admin admission screen. Dean/Faculty users own evaluation, advising, manual subject selection, and snapshot finalization. The admin admission page only reads the snapshot and validates handoff readiness until the snapshot is finalized with subject lines.

## 2026-06-15 Registrar Scope Decision

For the current bridge, Registrar owns only the Dean / Faculty irregular new-enrollee workflow. Regular applicant pre-registration, automated sectioning, cashier/payment handling, and normal student-number issuance remain outside Registrar scope.

Registrar now protects against duplicate student creation: if a student number already exists for the applicant reference, Registrar routes staff to Student Profile / Cashier continuation instead of generating another ID.

## Confirmed Workflow

1. Applicant is identified as irregular/transferee from prior-school fields, admission classification, or Year 2+ entry.
2. Faculty/Dean opens Registrar: `/registrar/faculty/irregular-advising?refNo={reference_number}`.
3. Faculty/Dean saves the snapshot header with program, year, semester, fee header fields, and notes.
4. Faculty/Dean adds one or more subject lines from the active curriculum.
5. Faculty/Dean finalizes the snapshot.
6. Admission/Admin opens `/registrar/admin/admission-acceptance?refNo={reference_number}`.
7. Registrar handoff readiness is allowed only after the shared snapshot has at least one subject line, is finalized, and the snapshot program matches the selected admission program.

## Role Split

Faculty/Dean owns:

- Snapshot header save.
- Subject line add/remove.
- Snapshot finalize/reopen.
- Advising notes and section code input.

Admission/Admin owns:

- Applicant review.
- Read-only snapshot preview.
- Read-only handoff readiness check.
- Final applicant qualification and cashier continuation in the external Admission / Cashier systems.

## Registrar URLs

Faculty/Dean advising UI:

```text
GET /registrar/faculty/irregular-advising?refNo={reference_number}
```

Faculty/Dean write endpoints:

```text
POST /registrar/faculty/pre-reg/save
POST /registrar/faculty/pre-reg/add-subject
POST /registrar/faculty/pre-reg/remove-subject
POST /registrar/faculty/pre-reg/finalize
POST /registrar/faculty/pre-reg/reopen
GET  /registrar/faculty/pre-reg/{reference_number}/snapshot
```

Admission/Admin read endpoint:

```text
GET /registrar/admin/pre-reg/{reference_number}/snapshot
```

Admission/Admin review UI:

```text
GET /registrar/admin/admission-acceptance?refNo={reference_number}
```

## Shared Tables

Registrar creates and writes these tables if missing:

```text
applicant_pre_reg_snapshots
applicant_pre_reg_subject_lines
```

Important snapshot fields:

```text
snapshot_id
applicant_id
reference_number
program_code
program_name
year_level
semester_number
enrollment_type
snapshot_source
snapshot_status
total_units
tuition_amount
misc_amount
assessment_amount
notes
evaluation_finalized_at
created_by
updated_by
finalized_by
created_at
updated_at
```

Important subject-line fields:

```text
line_id
snapshot_id
reference_number
course_id
course_code
course_title
units
year_level
semester_number
section_code
sort_order
created_at
```

## Readiness Contract For Admission

Admission should treat an irregular snapshot as ready when:

```text
exists = true
ready = true
line_count > 0
subject_lines is not empty
snapshot.program_code matches selected admission program
finalized = true
snapshot.snapshot_status = FINAL or snapshot.evaluation_finalized_at is not null
```

Current Registrar handoff readiness check enforces:

```text
Irregular applicant: snapshot required
Irregular applicant: at least one subject line required
Irregular applicant: snapshot must be finalized
Irregular applicant: snapshot program must match selected program
Regular applicant: continue through Admission and Cashier, not Registrar handoff validation
Existing student number for applicant reference: do not generate another student number
```

## JSON Shape

Example endpoint:

```text
GET /registrar/admin/pre-reg/IRREG-TEST-2026-002/snapshot
```

Example response shape:

```json
{
  "exists": true,
  "reference_number": "IRREG-TEST-2026-002",
  "snapshot": {
    "snapshot_id": 2,
    "applicant_id": 64,
    "reference_number": "IRREG-TEST-2026-002",
    "program_code": "BSIT",
    "program_name": "Bachelor of Science in Information Technology",
    "year_level": 2,
    "semester_number": 1,
    "enrollment_type": "IRREGULAR",
    "snapshot_source": "REGISTRAR",
    "snapshot_status": "FINAL",
    "total_units": 1.00,
    "tuition_amount": 0.00,
    "misc_amount": 0.00,
    "assessment_amount": 0.00,
    "notes": "Faculty advising handoff test snapshot",
    "evaluation_finalized_at": "2026-06-14T19:23:08",
    "created_by": "prof",
    "updated_by": "prof",
    "finalized_by": "prof"
  },
  "subject_lines": [
    {
      "line_id": 2,
      "course_id": 214,
      "course_code": "AECO 11",
      "course_title": "Emilian Culture",
      "units": 1.00,
      "year_level": 1,
      "semester_number": 1,
      "section_code": "IRREG-A",
      "sort_order": 1
    }
  ],
  "line_count": 1,
  "ready": true,
  "finalized": true
}
```

Note: `snapshot_source` remains `REGISTRAR` as the cross-system source contract. The faculty/dean actor is visible through `created_by`, `updated_by`, and `finalized_by`.

## Test Accounts

Faculty/Dean-side test:

```text
username: prof
password: 1234
```

Admin/Admission-side test:

```text
username: admin
password: 1234
```

## Test References

Completed through original registrar/admin smoke test:

```text
IRREG-TEST-2026-001
```

Finalized through Faculty/Dean advising smoke test and left ready for Admission consumption:

```text
IRREG-TEST-2026-002
```

Current known state for `IRREG-TEST-2026-002`:

```text
exists = true
ready = true
finalized = true
program_code = BSIT
line_count = 1
subject = AECO 11
created_by = prof
finalized_by = prof
```

## Registrar Code References

Snapshot service:

```text
src/main/java/com/iuims/registrar/admission/ApplicantPreRegSnapshotService.java
```

Admission read/gate controller:

```text
src/main/java/com/iuims/registrar/admission/AdmissionController.java
```

Faculty/Dean advising controller:

```text
src/main/java/com/iuims/registrar/faculty/FacultyIrregularAdvisingController.java
```

Faculty/Dean advising UI:

```text
src/main/resources/templates/faculty_irregular_advising.html
```

Admin read-only admission UI:

```text
src/main/resources/templates/admin_admission_acceptance.html
```

Faculty menu entry point:

```text
src/main/resources/templates/grades_menu.html
```

Seed script:

```text
db/demo_scripts/15_seed_irregular_admission_alignment.sql
```

## Admission Team Action Items

1. Read from `applicant_pre_reg_snapshots` and `applicant_pre_reg_subject_lines` using `reference_number` or `applicant_id`.
2. Prefer rows where `snapshot_source = 'REGISTRAR'`.
3. Treat `line_count > 0` plus finalized snapshot status as the minimum readiness rule.
4. Build irregular pre-reg PDF from `subject_lines`, not from block first-year curriculum.
5. Show an irregular/transferee pending-advising state when the snapshot is missing or has no subject lines.
6. Do not scrape Enrollment3 for irregular pre-reg data; Registrar is now the writer and Admission is the reader.

## Verification Completed

Compiled Registrar:

```text
mvn -q -DskipTests compile
```

Live smoke checks completed:

```text
Faculty page loads for prof / 1234
Faculty save endpoint works
Faculty add-subject endpoint works
Faculty finalize endpoint works
Faculty snapshot JSON returns ready/finalized
Admin admission page reads the finalized snapshot
Admin admission page has no pre-reg write forms
```

## Caveats

- DevTools hot reload has been unreliable in this workspace. Restart Registrar after controller/template edits.
- `snapshot_source = REGISTRAR` is retained for compatibility with the planned shared-table contract, even though the UI owner is Faculty/Dean.
- The current registrar readiness check requires `snapshot_status = FINAL` or `evaluation_finalized_at IS NOT NULL`, plus at least one subject line.
