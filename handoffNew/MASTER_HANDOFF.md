# Registrar + Enrollment Cleanup Handoff

> **SUPERSEDED for new PC / current state (2026-06-09).** Batch ledger below is frozen at mid-sprint.  
> **Use instead:** `START_HERE_NEW_PC_HANDOFF.md` → `HANDOFF_UPDATES_20260609.md` → `READINESS_CLOSURE_20260608.md` → `MASTER_DEMO_UAT_MANUAL.md`.  
> This file remains for historical architecture and batch sequencing context only.

## 1. Purpose

This document is the full handoff package for continuing the registrar and enrollment stabilization work in a new terminal/session.

It includes:

- system overview
- key findings from analysis
- risky seams identified across both apps
- the full implementation strategy
- the batch-by-batch execution plan
- the tracking checklist
- the active Batch 1 plan
- the exact progress already made in code
- the safest next steps

This handoff is intentionally comprehensive so the next agent does not need to rediscover architecture, scope, or sequencing.

## 2. Workspace and Apps

Root workspace:

- `D:\new`

Applications:

- `D:\new\registrar`
- `D:\new\enrollment3`

These two apps share one database/schema and communicate through shared tables, not through a service API boundary.

## 3. Architecture Summary

### 3.1 High-level roles

Registrar app:

- stronger system of record
- owns admissions, curriculum, fee administration, term governance, grading workflows, scholarship flows, faculty and academic administration

Enrollment app:

- operational enrollment/cashier side
- handles subject loading, finalization, assessment, ledger, payments, cashier views, and enrollment-side enforcement

### 3.2 Integration model

The apps integrate through the shared schema. Important shared tables include:

- `system_settings`
- `academic_terms`
- `sys_users`
- `students`
- `student_enlistments`
- `payments`
- `student_ledger`
- `program_fee_settings`
- `grades`
- `curriculum_*`

There is no real HTTP service boundary here. The schema is the contract.

### 3.3 Current contract assumptions we planned to standardize on

- `system_settings.CURRENT_ACADEMIC_TERM` is the only current-term authority
- `student_number` is the canonical transaction key
- `student_enlistments.enlistment_status` is the source of truth for staged vs committed lifecycle
- `program_fee_settings` is the only live fee source

## 4. What Was Analyzed Before Coding

We did an architectural and risk review first before editing anything.

### 4.1 Registrar-side major findings

- registrar still had a legacy `GlobalTermService` reading `sys_parameters.CURRENT_TERM`
- scholarship and walk-in flows still relied on that old helper
- other registrar flows, and enrollment, were already centered on `system_settings.CURRENT_ACADEMIC_TERM`
- registrar had a broken roster query using `student_enlistment` singular and `schedule_id`
- registrar still had legacy `jp_*` mirror writes in some paths
- registrar still had a stale `StudentEnlistment` entity/repository shape relative to live SQL usage

### 4.2 Enrollment-side major findings

- enrollment already had stronger active-term logic via `AcademicTermService`
- enrollment still had resilient fallback behavior that could hide misconfiguration
- official-load filtering still treated `NULL` enlistment status as committed
- fee logic mostly moved to `program_fee_settings`, but there were still fallback/default and legacy audit-path issues
- legacy `jp_*` sync still existed in some controllers

## 5. Risky Seams Identified

These are the major seams we identified, in priority order.

### 5.1 Term resolution seam

Why risky:

- registrar used two different current-term authorities
- scholar/walk-in flows could disagree with enrollment/cashier/admin flows
- term identity influences billing, term close, availability, and reporting

Main files originally involved:

- `D:/new/registrar/src/main/java/com/iuims/registrar/core/GlobalTermService.java`
- `D:/new/registrar/src/main/java/com/iuims/registrar/portal/ScholarController.java`
- `D:/new/registrar/src/main/java/com/iuims/registrar/scholarship/ScholarEnrollmentService.java`
- `D:/new/enrollment3/src/main/java/com/example/enrollment/service/AcademicTermService.java`

### 5.2 Enlistment lifecycle seam

Why risky:

- `COMMITTED_ONLY` still counted `NULL` as official
- raw writes still bypassed lifecycle-aware paths
- staged rows could bleed into official assessment/load logic

### 5.3 Fee path seam

Why risky:

- enrollment still had hardcoded/local fallback behavior
- `fee_fallback_enabled` looked configurable but was not really enforced
- a legacy `program_fee_rates` path still existed in the assessment snapshot logic

### 5.4 Legacy mirror seam

Why risky:

- both apps still wrote `jp_students` / `jp_student_enlistments`
- failures were often swallowed
- could create silent dual-truth drift

### 5.5 Registrar schema/query drift seam

Why risky:

- a clear registrar roster bug existed
- registrar enlistment model did not cleanly match the live shared table shape

## 6. Full Master Implementation Strategy

This is the agreed implementation order and should remain the source-of-truth sequence.

### Batch order

1. Term authority
2. Enlistment lifecycle
3. Fee unification
4. Legacy mirror retirement
5. Registrar schema/query cleanup
6. Identity/profile normalization
7. Full regression and hardening

### Why this order

- term authority comes first because bad term identity poisons everything downstream
- enlistment lifecycle comes next because official vs staged correctness affects fees, roster counts, and subject status
- fee unification comes after term and lifecycle are stable
- mirror retirement comes after canonical paths are trustworthy
- registrar schema/query cleanup comes after core semantics are stable
- identity/profile normalization comes after the operational contracts are clearer
- full regression happens last

## 7. Detailed Batch-by-Batch Plan

## Batch 1: Term Authority

Goal:

- unify registrar-side current-term authority on `system_settings.CURRENT_ACADEMIC_TERM`
- align term/profile writes so student term fields start from the same canonical source

Primary files:

- `D:/new/registrar/src/main/java/com/iuims/registrar/core/GlobalTermService.java`
- `D:/new/registrar/src/main/java/com/iuims/registrar/portal/ScholarController.java`
- `D:/new/registrar/src/main/java/com/iuims/registrar/scholarship/ScholarEnrollmentService.java`
- `D:/new/registrar/src/main/java/com/iuims/registrar/portal/PortalController.java`
- `D:/new/registrar/src/main/java/com/iuims/registrar/admission/FinanceAdmissionService.java`
- `D:/new/registrar/src/main/java/com/iuims/registrar/academic/AcademicGradingService.java`
- `D:/new/enrollment3/src/main/java/com/example/enrollment/service/AcademicTermService.java`
- `D:/new/enrollment3/src/main/java/com/example/enrollment/service/TermContextService.java`
- `D:/new/enrollment3/src/main/java/com/example/enrollment/service/StudentProfileService.java`

Tasks:

- replace registrar use of `sys_parameters.CURRENT_TERM`
- create one registrar-side canonical term resolver
- make scholarship fallback `term_year` use student-style term values
- ensure admissions write `semester` and `term_year` consistently into `sys_users` and `students`
- verify enrollment-side term resolution is consistent with registrar’s canonical behavior

Done when:

- scholar cashier, walk-in admission, registrar portal, enrollment cashier, and ledger views all resolve the same current term
- no registrar production flow depends on `sys_parameters.CURRENT_TERM`

Hold line:

- do not touch enlistment lifecycle yet
- do not touch fee logic yet
- do not retire mirror tables yet

## Batch 2: Enlistment Lifecycle

Goal:

- make staged vs committed enlistments strict and reliable

Primary files:

- `D:/new/enrollment3/src/main/java/com/example/enrollment/service/EnlistmentSchemaService.java`
- `D:/new/registrar/src/main/java/com/iuims/registrar/core/EnlistmentSchemaService.java`
- `D:/new/enrollment3/src/main/java/com/example/enrollment/service/EnlistmentWriteService.java`
- `D:/new/enrollment3/src/main/java/com/example/enrollment/controller/AdminController.java`
- `D:/new/enrollment3/src/main/java/com/example/enrollment/controller/RegistrarController.java`
- `D:/new/enrollment3/src/main/java/com/example/enrollment/service/EnrollmentIntegrationService.java`
- `D:/new/enrollment3/src/main/java/com/example/enrollment/service/SchedulingService.java`
- `D:/new/registrar/src/main/java/com/iuims/registrar/portal/ScholarController.java`
- `D:/new/registrar/src/main/java/com/iuims/registrar/scholarship/ScholarEnrollmentService.java`
- `D:/new/registrar/src/main/java/com/iuims/registrar/jaypee/JaypeeIntegrationService.java`
- `D:/new/enrollment3/src/main/java/com/example/enrollment/service/TermAssessmentService.java`
- `D:/new/enrollment3/src/main/java/com/example/enrollment/service/FinancialService.java`

Tasks:

- stop treating `NULL` enlistment status as committed in live `COMMITTED_ONLY`
- keep legacy repair in startup/migration concerns, not runtime semantics
- route enrollment-side subject writes through explicit lifecycle-aware service paths
- route registrar-side subject writes through one committed path
- verify official assessment and unit-count readers use strict official-load logic

Done when:

- staged rows never affect official load, official fees, scholar computations, or section counts

## Batch 3: Fee Unification

Goal:

- make `program_fee_settings` the only live fee source and make missing-fee behavior intentional

Primary files:

- `D:/new/enrollment3/src/main/java/com/example/enrollment/service/FeeScheduleService.java`
- `D:/new/enrollment3/src/main/java/com/example/enrollment/service/EnrollmentSettingsService.java`
- `D:/new/enrollment3/src/main/java/com/example/enrollment/service/FinancialService.java`
- `D:/new/enrollment3/src/main/java/com/example/enrollment/service/TermFeeAdminService.java`
- `D:/new/enrollment3/src/main/java/com/example/enrollment/repository/ProgramFeeSettingRepository.java`
- `D:/new/registrar/src/main/java/com/iuims/registrar/finance/TermFeeAdminService.java`
- `D:/new/registrar/src/main/java/com/iuims/registrar/finance/ProgramFeeSettingRepository.java`
- `D:/new/registrar/src/main/java/com/iuims/registrar/finance/ProgramFeeSetting.java`

Tasks:

- ensure tuition, RLE, misc, and other fees all come from `program_fee_settings`
- remove or truly enforce `fee_fallback_enabled`
- remove runtime dependence on legacy `program_fee_rates`
- align fee repository precedence rules across both apps
- decide whether missing official fee rows fail closed or use explicit override behavior

Done when:

- display assessment, posted assessment, and audit snapshot all derive from the same source

## Batch 4: Legacy Mirror Retirement

Goal:

- remove hidden dual writes to `jp_students` and `jp_student_enlistments`

Primary files:

- `D:/new/enrollment3/src/main/java/com/example/enrollment/controller/EnrollmentController.java`
- `D:/new/enrollment3/src/main/java/com/example/enrollment/controller/AdminController.java`
- `D:/new/enrollment3/src/main/java/com/example/enrollment/controller/RegistrarController.java`
- `D:/new/registrar/src/main/java/com/iuims/registrar/academic/AcademicGradingService.java`

Tasks:

- remove `jp_*` sync from finalize, undo, status sync, and term transition flows
- isolate any remaining legacy dependency behind one explicit adapter if truly needed

Done when:

- canonical flows rely only on canonical shared tables and not mirror tables

## Batch 5: Registrar Schema and Query Cleanup

Goal:

- align registrar code with the real shared schema

Primary files:

- `D:/new/registrar/src/main/java/com/iuims/registrar/academic/AcademicGradingService.java`
- `D:/new/registrar/src/main/java/com/iuims/registrar/enrollment/StudentEnlistment.java`
- `D:/new/registrar/src/main/java/com/iuims/registrar/enrollment/StudentEnlistmentRepository.java`
- `D:/new/registrar/src/main/java/com/iuims/registrar/academic/ClassSectionRepository.java`

Tasks:

- fix the broken registrar roster query
- realign or reduce the stale registrar enlistment entity/repository
- re-check registrar section counts and roster queries

Done when:

- registrar roster, counts, and close-section checks use the live shared schema correctly

## Batch 6: Identity and Profile Normalization

Goal:

- reduce mixed-key ambiguity and stabilize profile propagation

Primary files:

- `D:/new/enrollment3/src/main/java/com/example/enrollment/service/StudentLedgerService.java`
- `D:/new/enrollment3/src/main/java/com/example/enrollment/service/StudentProfileService.java`
- `D:/new/registrar/src/main/java/com/iuims/registrar/core/Student.java`
- `D:/new/registrar/src/main/java/com/iuims/registrar/core/SysUser.java`
- `D:/new/registrar/src/main/java/com/iuims/registrar/jaypee/JaypeeIntegrationService.java`

Tasks:

- narrow runtime behavior toward `student_number` as canonical transaction key
- keep legacy-key migration only as compatibility scaffolding
- ensure profile fields remain aligned between `students` and `sys_users`

Done when:

- runtime behavior no longer depends on mixed `student_number` / `user_id` ambiguity

## Batch 7: Full Regression and Hardening

Goal:

- verify the entire cleaned system behaves consistently across both apps

Verification scope:

- admission
- walk-in cashier
- scholar cashier
- subject add/drop
- staged enrollment and finalize
- official assessment
- ledger term switching
- registrar roster and section counts
- term transition

Done when:

- cross-app term, load, billing, and profile behavior all agree

2026-06-07 active-path result:

- controlled cross-app regression passed with disposable `B7REG-001`
- enrollment verified section assignment, block staging, payment, finalization, committed official load, official ledger, COR export, faculty roster, and canonical grade write
- registrar verified Student Manager profile, BSCPE roster, Settings readiness, Term Fees, and registrar print-COR
- readiness hardening now exposes incomplete primary-rate fee scopes in Settings, readiness JSON, and term-transition errors
- scholar cashier hardening/runtime verification completed with disposable `SCHREG-001`: scholarship grant, current-term subject enlistment, committed official load display, scholarship-aware walk-in assessment display, and payment posting all used canonical `student_number` keys
- temporary `B7REG-%` rows were cleaned after verification
- temporary `SCHREG-%` rows were cleaned after verification
- deprecated registrar walk-in/payment and registrar-side enrollment screens were intentionally excluded
- remaining production-readiness blockers are data/UAT items: official fee primary-rate completion, remaining active curricula, and full term-transition rehearsal

## 8. Progress Checklist / Tracking Table

Use this as the active progress ledger.

| Batch | Status | Scope | Primary Files | Verification |
|---|---|---|---|---|
| 1 | in progress | Unify current-term authority | `GlobalTermService`, `ScholarController`, `ScholarEnrollmentService`, `AcademicTermService`, `TermContextService` | Scholar cashier, walk-in, registrar portal, enrollment cashier, and ledger resolve the same active term |
| 1 | in progress | Align term/profile propagation | `StudentProfileService`, `FinanceAdmissionService`, `JaypeeIntegrationService` | `students` and `sys_users` agree on `term_year`, `semester`, `year_level` after admission and sync |
| 2 | todo | Make committed vs staged strict | enrollment + registrar `EnlistmentSchemaService` | `COMMITTED_ONLY` never includes ambiguous rows |
| 2 | todo | Route enrollment writes through lifecycle service | `EnlistmentWriteService`, `AdminController`, `RegistrarController`, `EnrollmentIntegrationService`, `SchedulingService` | New subject writes always carry explicit lifecycle state |
| 2 | todo | Route registrar writes through committed path | `ScholarController`, `ScholarEnrollmentService`, `JaypeeIntegrationService` | Registrar cannot create statusless official enlistments |
| 2 | todo | Re-check official load readers | `TermAssessmentService`, `FinancialService`, `ScholarEnrollmentService`, `JaypeeIntegrationService` | Staged rows never affect official units, fees, or counts |
| 3 | todo | Make `program_fee_settings` sole live fee source | `FeeScheduleService`, `FinancialService`, `TermFeeAdminService` (both apps) | Display and saved assessment use same fee source |
| 3 | todo | Fix fallback policy | `EnrollmentSettingsService`, `FeeScheduleService` | Missing-fee behavior is explicit and consistent |
| 3 | todo | Align fee repository precedence | both `ProgramFeeSettingRepository` files | Same scope resolves same fee row |
| 4 | done | Remove enrollment `jp_*` sync | `EnrollmentController`, `AdminController`, `RegistrarController` | Finalize/undo verified without mirror writes |
| 4 | done | Remove registrar `jp_*` sync | `AcademicGradingService` | Term transition/status sync no longer touch mirrors |
| 5 | done | Fix registrar roster query | `AcademicGradingService` | Registrar Student Manager roster runtime-verified with current-term official unit computation |
| 5 | done | Reconcile stale enlistment entity/repo | `StudentEnlistment`, `StudentEnlistmentRepository`, `ClassSectionRepository` | Stale JPA model and stale count helper removed; active counts use live shared shape |
| 6 | done | Normalize canonical transaction key | `StudentLedgerService`, `JaypeeIntegrationService`, `FacultyController`, `AcademicGradingService` | Runtime reads/writes rely on `student_number`; isolated faculty roster runtime-verified |
| 6 | done | Normalize profile sync | `StudentProfileService`, registrar `Student`, registrar `SysUser` | Active profile fallback no longer reads enlistments by numeric `user_id`; broader profile behavior rolls into Batch 7 regression |
| 7 | done (active-path) | Full regression and hardening | key registrar and enrollment flows | Controlled cross-app and scholar cashier runtime pass completed; production UAT still needs fee/curriculum data readiness plus term-transition rehearsal |

Working rules:

- finish Batch 1 before touching Batch 2
- verify each batch before opening the next one
- if a new issue is discovered, log it into this document before expanding scope

## 9. Batch 1 Concrete Sprint Plan

This was the active working sprint plan before coding began.

### Batch 1 checklist

1. Replace registrar legacy term source
- files:
  - `D:/new/registrar/src/main/java/com/iuims/registrar/core/GlobalTermService.java`
  - `D:/new/registrar/src/main/java/com/iuims/registrar/portal/ScholarController.java`
  - `D:/new/registrar/src/main/java/com/iuims/registrar/scholarship/ScholarEnrollmentService.java`
- target:
  remove reliance on `sys_parameters.CURRENT_TERM`

2. Create one registrar-side canonical term resolver
- likely target:
  a new helper under `registrar/core`
- target:
  expose current DB term code, student-style term year, current `term_id`, and current semester

3. Tighten enrollment term entry points
- files:
  - `D:/new/enrollment3/src/main/java/com/example/enrollment/service/AcademicTermService.java`
  - `D:/new/enrollment3/src/main/java/com/example/enrollment/service/TermContextService.java`
- target:
  make fallback behavior consistent and predictable

4. Align profile-term propagation
- files:
  - `D:/new/enrollment3/src/main/java/com/example/enrollment/service/StudentProfileService.java`
  - `D:/new/registrar/src/main/java/com/iuims/registrar/jaypee/JaypeeIntegrationService.java`
  - `D:/new/registrar/src/main/java/com/iuims/registrar/admission/FinanceAdmissionService.java`
- target:
  keep `term_year`, `semester`, and `year_level` aligned between `students` and `sys_users`

5. Batch 1 smoke checks
- scholar cashier fallback term
- walk-in admission current term
- enrollment cashier active term
- ledger active term selection
- term label shown in portal/dashboard
- student `term_year` after admission and sync

### Batch 1 stop line

Do not edit:

- `enlistment_status` semantics
- `student_enlistments` lifecycle
- fee source / fee fallback behavior
- `jp_*` retirement

## 10. Actual Batch 1 Progress Already Made in Code

Batch 1 was started and partially implemented.

### 10.1 New file added

Added:

- `D:/new/registrar/src/main/java/com/iuims/registrar/core/RegistrarTermService.java`

Purpose:

- canonical registrar-side term resolver based on `system_settings.CURRENT_ACADEMIC_TERM`

Current behavior:

- reads current setting
- normalizes DB code, `SL`, and legacy `SL_`
- resolves `academic_terms`
- exposes:
  - current academic term row
  - current DB term code
  - current `term_id`
  - current semester
  - current student-style term for a given year level

### 10.2 GlobalTermService changed

File:

- `D:/new/registrar/src/main/java/com/iuims/registrar/core/GlobalTermService.java`

Previous behavior:

- directly read `sys_parameters.CURRENT_TERM`

New behavior:

- wraps `RegistrarTermService`
- `getCurrentGlobalTermCode()` now returns DB term code
- added:
  - `getCurrentStudentTermYear(int yearLevel)`
  - `getCurrentTermId()`
  - `getCurrentSemesterNumber()`

Important note:

The meaning of this service has changed. Hidden callers may still assume the old output shape.

### 10.3 ScholarController updated

File:

- `D:/new/registrar/src/main/java/com/iuims/registrar/portal/ScholarController.java`

Change:

- scholar walk-in fallback no longer uses DB term code
- now uses:
  `globalTermService.getCurrentStudentTermYear(yearLevel)`

### 10.4 ScholarEnrollmentService updated

File:

- `D:/new/registrar/src/main/java/com/iuims/registrar/scholarship/ScholarEnrollmentService.java`

Changes:

- applicant fallback `term_year` now uses student-style current term:
  `globalTermService.getCurrentStudentTermYear(1)`
- `resolveCurrentTermId(studentNumber)` now falls back to:
  `globalTermService.getCurrentTermId()`

### 10.5 PortalController updated

File:

- `D:/new/registrar/src/main/java/com/iuims/registrar/portal/PortalController.java`

Changes:

- added `GlobalTermService` dependency
- dashboard now gets current DB term code from the wrapper instead of raw JDBC to `CURRENT_ACADEMIC_TERM`

### 10.6 FinanceAdmissionService updated

File:

- `D:/new/registrar/src/main/java/com/iuims/registrar/admission/FinanceAdmissionService.java`

Changes made:

- added `GlobalTermService` dependency
- admissions now resolve `admissionTermYear` earlier
- admissions now use canonical semester fallback via `getCurrentSemesterNumber()`
- `sys_users` insert now writes:
  - `semester`
  - `term_year`
- `students` insert now writes:
  - `semester`
  - `term_year`
- `payments` insert now uses the same semester and term year
- `resolveAdmissionTermYearSl()` now does an early canonical return:
  `globalTermService.getCurrentStudentTermYear(yearLevel)`

Important note:

The older fallback logic under `resolveAdmissionTermYearSl()` is still present. That is acceptable for now and was left intentionally as a safety net.

## 11. Current File State Summary for the Next Agent

Start with these files first:

- `D:/new/registrar/src/main/java/com/iuims/registrar/core/RegistrarTermService.java`
- `D:/new/registrar/src/main/java/com/iuims/registrar/core/GlobalTermService.java`
- `D:/new/registrar/src/main/java/com/iuims/registrar/portal/ScholarController.java`
- `D:/new/registrar/src/main/java/com/iuims/registrar/portal/PortalController.java`
- `D:/new/registrar/src/main/java/com/iuims/registrar/scholarship/ScholarEnrollmentService.java`
- `D:/new/registrar/src/main/java/com/iuims/registrar/admission/FinanceAdmissionService.java`

Files that likely need review after compile:

- `D:/new/registrar/src/main/java/com/iuims/registrar/academic/AcademicGradingService.java`
- `D:/new/registrar/src/main/java/com/iuims/registrar/jaypee/JaypeeIntegrationService.java`
- `D:/new/enrollment3/src/main/java/com/example/enrollment/service/AcademicTermService.java`
- `D:/new/enrollment3/src/main/java/com/example/enrollment/service/TermContextService.java`
- `D:/new/enrollment3/src/main/java/com/example/enrollment/service/StudentProfileService.java`

## 12. Known Risks and Cautions

### 12.1 Constructor wiring fallout

Compile is required because these constructor dependencies changed:

- `GlobalTermService`
- `PortalController`
- `FinanceAdmissionService`

### 12.2 Output shape risk

The new canonical resolver currently emits student term values in `SL...` format without underscore, for example:

- `SL2025202611`

But older docs and some legacy code references use:

- `SL_1220252026`

The system appears to tolerate both in multiple places, but this must be checked carefully in any Batch 1 verification that compares or parses `term_year`.

### 12.3 Hidden callers

Any hidden caller of `GlobalTermService.getCurrentGlobalTermCode()` may still assume it returns a student-style term value. It no longer does. It now returns DB term code.

### 12.4 No tests have been run

None of the Batch 1 changes were compile-tested or runtime-tested in the prior session.

### 12.5 Git unavailable in prior terminal

The prior session could not produce `git diff` or `git status` because `git` was unavailable in that terminal environment.

## 13. What Must Not Be Touched Yet

Do not move into these until Batch 1 is compiled, verified, and summarized:

- Batch 2 enlistment lifecycle changes
- Batch 3 fee unification
- Batch 4 mirror retirement
- Batch 5 registrar roster/entity cleanup
- Batch 6 identity normalization

Specifically avoid touching right now:

- `enlistment_status` semantics
- subject add/drop lifecycle behavior
- `program_fee_settings` cleanup
- `fee_fallback_enabled`
- `jp_students`
- `jp_student_enlistments`
- registrar roster SQL bug

## 14. Best Next Steps for the Next Agent

### Step 1: compile registrar

Compile `registrar` first and fix only constructor/import fallout introduced by Batch 1.

Priority files:

- `D:/new/registrar/src/main/java/com/iuims/registrar/core/RegistrarTermService.java`
- `D:/new/registrar/src/main/java/com/iuims/registrar/core/GlobalTermService.java`
- `D:/new/registrar/src/main/java/com/iuims/registrar/portal/PortalController.java`
- `D:/new/registrar/src/main/java/com/iuims/registrar/admission/FinanceAdmissionService.java`
- `D:/new/registrar/src/main/java/com/iuims/registrar/scholarship/ScholarEnrollmentService.java`
- `D:/new/registrar/src/main/java/com/iuims/registrar/portal/ScholarController.java`

### Step 2: verify semantics of RegistrarTermService

Inspect and verify:

- normalization of DB code
- normalization of `SL`
- normalization of `SL_`
- output shape of `getCurrentStudentTermYear(yearLevel)`

### Step 3: run Batch 1 manual verification

Minimum checks:

- registrar dashboard active term loads correctly
- scholar walk-in fallback term_year is correct when missing
- scholar cashier applicant fallback term_year is correct
- admission approval writes matching `semester` and `term_year` into:
  - `sys_users`
  - `students`
  - `payments`

### Step 4: review remaining Batch 1 alignment

Only after registrar compile/verification:

- review whether `AcademicGradingService` should consume the new resolver now or can wait
- review whether `JaypeeIntegrationService` needs any Batch 1 alignment
- review whether enrollment-side term/profile files need actual code changes or only validation

### Step 5: stop and summarize Batch 1

Do not begin Batch 2 until Batch 1 has:

- compiled cleanly
- been manually verified
- been summarized with any residual issues

## 15. Mental Model to Preserve

If the next agent wants the simplest way to think about this:

- `RegistrarTermService` is the new canonical registrar term interpreter
- `GlobalTermService` is now just a compatibility wrapper
- scholarship fallback `term_year` must use student-style current term
- dashboard/portal academic term lookups must use canonical DB term code
- admissions must write `semester` and `term_year` consistently into both `sys_users` and `students`
- do not widen scope into enlistment or fees until this is stable

## 16. Suggested Pickup Prompt for the Next Agent

Use this if needed:

Continue Batch 1 only in `D:\new` for the shared registrar/enrollment cleanup. Start by compiling `registrar` and fixing constructor/import fallout from the new `RegistrarTermService` and updated `GlobalTermService`, `PortalController`, `ScholarController`, `ScholarEnrollmentService`, and `FinanceAdmissionService`. Then verify that scholar fallback term_year, portal active term, and admission-created student term fields all align with `system_settings.CURRENT_ACADEMIC_TERM`. Do not move into enlistment lifecycle, fee cleanup, jp_* retirement, or roster bug fixes yet unless something strictly blocks Batch 1 coherence.
