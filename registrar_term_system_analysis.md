# Registrar Term System Analysis

## Scope
This document is a registrar-side analysis only. It captures the current behavior, risks, and data contracts that the next agent should preserve before any implementation plan is written.

## Executive Summary
The registrar already has several term-related features, but they are split across different flows:
- term creation is metadata-only
- term activation is handled by the global term transition flow
- fee editing is term/program/year/semester scoped
- curriculum management is program-global, not term-specific

This means the registrar does not yet have a single, unified "create term and configure everything" workflow. If we add one later, it must stay compatible with the enrollment side because enrollment already reads the same shared term and fee tables.

## Current Registrar Behavior

### 1) Term creation is minimal
The Add Academic Term form in [`admin_settings.html`](C:/Users/admin/Downloads/6126/projects/registrar/src/main/resources/templates/admin_settings.html) only collects academic year, semester, start date, and end date. It does not configure curriculum, fees, or installment rules.

The actual insert logic lives in [`AcademicGradingService.java`](C:/Users/admin/Downloads/6126/projects/registrar/src/main/java/com/iuims/registrar/service/AcademicGradingService.java#L458). It:
- validates the academic year format
- builds a term code like `1120242025` or `2120242025`
- inserts a row into `academic_terms`
- defaults the new term to `INACTIVE`

Important point: this is only term metadata. It does not create a full term configuration snapshot.

### 2) Global term transition is the operational switch
The real term change is handled by [`triggerTermTransition`](C:/Users/admin/Downloads/6126/projects/registrar/src/main/java/com/iuims/registrar/service/AcademicGradingService.java#L640).

That flow:
- updates `system_settings.CURRENT_ACADEMIC_TERM`
- aligns `academic_terms.is_active` and `status`
- advances eligible students to the new term
- updates student year level and semester
- clears or resets some enrollment-related flags
- forwards unpaid balances through the ledger logic

This is the most sensitive part of the registrar term system because it affects student standing, term activity, and billing continuity.

### 3) Fee editing already exists, but only for a limited fee model
[`TermFeeAdminService.java`](C:/Users/admin/Downloads/6126/projects/registrar/src/main/java/com/iuims/registrar/service/TermFeeAdminService.java) edits the shared fee tables used by the system:
- `program_general_fees`
- `program_specific_fees`

It supports:
- tuition per unit
- RLE rate per hour
- MISC fees
- OTHER fees

It does not fully expose all fee groups that exist in the schema.

### 4) Curriculum management is program-level, not term-level
[`CurriculumSeederService.java`](C:/Users/admin/Downloads/6126/projects/registrar/src/main/java/com/iuims/registrar/service/CurriculumSeederService.java) seeds and activates curricula per program. It keeps one active curriculum per program, but it does not make curriculum a term-specific choice.

So, in registrar terms, curriculum is currently a program catalog, not a term configuration switch.

## Bugs and Risks Found

### A) Term creation does not configure dependent settings
The Add Academic Term flow creates a term row only. It does not capture any of the following as part of the term itself:
- curriculum activation choice
- fee rate snapshot
- installment plan
- per-term enrollment rules
- per-term schedule or grading defaults

That means a newly created term can exist in the database without the configuration needed to behave like a real operating term.

### B) The active-term switch is too aggressive
[`triggerTermTransition`](C:/Users/admin/Downloads/6126/projects/registrar/src/main/java/com/iuims/registrar/service/AcademicGradingService.java#L640) advances students in bulk and also resets state fields such as `admission_status`, `student_type`, `enrollment_blocked`, and `enrollment_start_time`.

Risk:
- manual exceptions can be overwritten
- a student's lifecycle state can be simplified too much
- blocked students may be cleared too early if the transition is not carefully controlled

### C) A missing term can create inconsistent global state
The transition flow writes `CURRENT_ACADEMIC_TERM` first, then tries to align the `academic_terms` table.

If the term code is invalid or the target row is missing, the system can end up with:
- a global current term value that does not match an active `academic_terms` row
- or a partially transitioned state

That is dangerous because downstream pages treat the active term as authoritative.

### D) Hardcoded fallback term code is risky
[`ScholarController.java`](C:/Users/admin/Downloads/6126/projects/registrar/src/main/java/com/iuims/registrar/controller/ScholarController.java#L39) falls back to a hardcoded term code when the student term and the global term are both missing.

Risk:
- silent misrouting of fee computation
- hidden config problems
- payment or enlistment records attached to the wrong term

### E) Fee groups are partially unreachable
The schema supports more fee groups than the registrar UI exposes, but [`TermFeeAdminService.java`](C:/Users/admin/Downloads/6126/projects/registrar/src/main/java/com/iuims/registrar/service/TermFeeAdminService.java#L75) currently only exposes `MISC` and `OTHER` for charge lines.

This means schema capability and UI capability are out of sync.

### F) Some stored fee columns are not actually used
`program_general_fees` includes columns such as `lab_fee_per_unit` and `comp_fee_per_unit`, but registrar runtime logic mostly reads tuition and RLE.

Risk:
- the schema suggests richer fee support than the runtime actually provides
- maintainers can assume a column is live when it is not

### G) Term-scoped fee lookup can still hide bad configuration
[`ScholarEnrollmentService.java`](C:/Users/admin/Downloads/6126/projects/registrar/src/main/java/com/iuims/registrar/service/ScholarEnrollmentService.java#L792) and related logic fall back to broader fee rows when exact rows are missing.

That is useful for resilience, but it can also hide configuration gaps and silently use the wrong rate.

### H) Fee selection precedence can be ambiguous
The `program_specific_fees` lookup uses a grouping strategy that favors the most recent matching row.

Risk:
- a broader fallback row can override a more intentional row if the data is messy
- exact term rows are not always obviously guaranteed to win unless the data is clean

### I) Curriculum is not term-specific in registrar
This is not a bug by itself, but it is a gap relative to the requested future design.

At present:
- one curriculum can be active per program
- the term creation flow does not choose a curriculum
- no term-scoped curriculum assignment exists in the registrar flow

## Shared Data Contracts Enrollment Depends On
Even though this document is registrar-focused, the following data is already shared with enrollment logic and should remain stable:
- `academic_terms`
- `system_settings.CURRENT_ACADEMIC_TERM`
- `program_general_fees`
- `program_specific_fees`
- `students.term_year`
- `student_enlistments`
- `payments`
- `student_ledger`

Any registrar change that alters term codes, fee scope, or active-term meaning will affect enrollment behavior.

## Constraints To Preserve
- Keep term code format consistent with the current `SL_*` and DB term code mapping.
- Preserve exactly one active term concept at a time.
- Avoid hardcoded fallback term values in production logic.
- Keep fee table writes readable by the existing fee and cashier code.
- Treat term creation and term activation as separate decisions unless the new workflow intentionally combines them.

## What The Next Agent Should Carry Forward
- Decide whether registrar should remain metadata-only for term creation or become a full term-configuration entry point.
- Decide which fee groups are actually supported by registrar and which should remain out of scope.
- Decide whether curriculum stays program-global or becomes selectable per term in a later phase.
- Preserve compatibility with enrollment data expectations while keeping implementation in registrar first.

## File References
- [`AcademicController.java`](C:/Users/admin/Downloads/6126/projects/registrar/src/main/java/com/iuims/registrar/controller/AcademicController.java)
- [`AcademicGradingService.java`](C:/Users/admin/Downloads/6126/projects/registrar/src/main/java/com/iuims/registrar/service/AcademicGradingService.java)
- [`TermFeeAdminService.java`](C:/Users/admin/Downloads/6126/projects/registrar/src/main/java/com/iuims/registrar/service/TermFeeAdminService.java)
- [`ScholarEnrollmentService.java`](C:/Users/admin/Downloads/6126/projects/registrar/src/main/java/com/iuims/registrar/service/ScholarEnrollmentService.java)
- [`ScholarController.java`](C:/Users/admin/Downloads/6126/projects/registrar/src/main/java/com/iuims/registrar/controller/ScholarController.java)
- [`CurriculumSeederService.java`](C:/Users/admin/Downloads/6126/projects/registrar/src/main/java/com/iuims/registrar/service/CurriculumSeederService.java)
- [`admin_settings.html`](C:/Users/admin/Downloads/6126/projects/registrar/src/main/resources/templates/admin_settings.html)
- [`admin_term_fees.html`](C:/Users/admin/Downloads/6126/projects/registrar/src/main/resources/templates/admin_term_fees.html)
