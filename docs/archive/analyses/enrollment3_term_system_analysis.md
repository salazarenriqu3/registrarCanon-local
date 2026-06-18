# Enrollment3 Term System Analysis

## Scope
This document is the enrollment-side companion to the registrar analysis. It focuses on the logic that already exists in `enrollment3` and the compatibility rules that the registrar updates must preserve.

## Executive Summary
Enrollment3 already has a mature term-aware core:
- registrar-active term resolution
- student term/year mapping
- term-aware fee schedule selection
- term assessment and ledger population
- installment-plan computation
- downpayment and payment-gate logic

Because of that, any registrar-side term redesign must keep the same term code meaning, fee scope, and active-term contract, or enrollment behavior will drift.

## Current Enrollment Behavior

### 1) Registrar term is the single source of truth
[`AcademicTermService.java`](C:/Users/admin/Downloads/6126/projects/enrollment3/src/main/java/com/example/enrollment/service/AcademicTermService.java) treats the registrar’s active term as authoritative.

Key behaviors:
- `getRegistrarActiveTerm()` reads `system_settings.CURRENT_ACADEMIC_TERM`
- it maps the current registrar term to `academic_terms`
- it prefers registrar state over local fallback logic
- term dropdowns and term-selection rules are built from that same source

This is the core contract that registrar changes must not break.

### 2) Student term state is normalized around SL_* values
[`TermContextService.java`](C:/Users/admin/Downloads/6126/projects/enrollment3/src/main/java/com/example/enrollment/service/TermContextService.java) and `AcademicTermService` both depend on `term_year` values like `SL_1120252026`.

Enrollment uses that encoding to:
- resolve a student’s current term
- map term codes back to `academic_terms.term_id`
- build current, past, and future term views
- determine whether a student can move into a term or stay on the current one

If the registrar changes term-code format, enrollment term logic will break.

### 3) Installment plans already exist in enrollment
[`EnrollmentSettingsService.java`](C:/Users/admin/Downloads/6126/projects/enrollment3/src/main/java/com/example/enrollment/service/EnrollmentSettingsService.java) manages both school-wide settings and term installment plans.

It already supports:
- enrollment policy values like downpayment, max units, and drop penalties
- a `term_installment_plan` table
- per-term installment retrieval with fallback to default rows
- hardcoded fallback installment rows if the database query fails

So, installment logic is real in enrollment, not just a template artifact.

### 4) Financial logic uses the installment plan and downpayment policy
[`FinancialService.java`](C:/Users/admin/Downloads/6126/projects/enrollment3/src/main/java/com/example/enrollment/service/FinancialService.java) consumes the settings and term plan to build the payment schedule.

It:
- computes total assessment
- computes required downpayment
- loads term-specific installment rows
- distributes the remaining balance across the plan rows
- computes line statuses such as PAID, PARTIAL, and PENDING
- exposes `installments`, `downpaymentAmount`, `downpaymentAmountDue`, and related model fields

This means fee and installment configuration are not abstract policy values. They directly affect the cashier UI and payment state.

### 5) Fee assessment is term-aware and has two supported sources
[`FeeScheduleService.java`](C:/Users/admin/Downloads/6126/projects/enrollment3/src/main/java/com/example/enrollment/service/FeeScheduleService.java) is the main fee lookup layer.

It supports:
- the current core tables path: `program_general_fees` and `program_specific_fees`
- an optional alternate path: `program_fee_rates` and `fee_types`
- a config switch to choose the alternate path
- fallback logic when exact rows are missing

Term-aware assessment is then computed in [`TermAssessmentService.java`](C:/Users/admin/Downloads/6126/projects/enrollment3/src/main/java/com/example/enrollment/service/TermAssessmentService.java).

## Bugs and Risks

### A) Dual fee engines are risky
`FeeScheduleService` can read from either the core fee tables or the alternate `program_fee_rates` path depending on config.

Risk:
- mixed configuration can produce different totals in cashier vs ledger vs assessment previews
- partial migration can create silent mismatches
- the code itself warns against enabling both paths in production without a clean migration

### B) Fallbacks can hide missing data
Both fee lookup and installment lookup use fallback layers.

Examples:
- `FeeScheduleService.fetchBestAvailableProgramFees()` can choose broader rows if an exact row is missing
- `EnrollmentSettingsService.getInstallmentPlan()` falls back to default rows or hardcoded defaults if per-term rows are absent

This is useful for resilience, but it can also hide configuration mistakes and make the system appear correct while using the wrong values.

### C) Installment plans are not fully admin-managed
Enrollment already reads `term_installment_plan`, but the current settings service is mostly read/update for simple key-value settings.

Risk:
- per-term installment plans are easy to forget
- the UI can show installment behavior without giving the user a first-class way to maintain the plan rows
- DB edits become the hidden source of truth

### D) Student type is not fully wired into alternate fee rates
`FeeScheduleService` includes a note that `student_type` is not currently wired into `FeeScheduleContext` for the alternate `program_fee_rates` path.

Risk:
- if that alternate path is enabled, some rate tiers may never be selected correctly
- student-type-specific pricing is only partially implemented

### E) Term resolution is very sensitive to registrar correctness
`AcademicTermService` and `TermContextService` both assume the registrar’s active term is valid and mappable.

If the registrar term is missing, malformed, or inconsistent:
- term dropdowns can be wrong
- assessment can fall back to empty or default results
- term-year resolution can fail silently
- payment schedule and ledger status can become misleading

### F) The payment schedule depends on accurate fee totals
`FinancialService` uses the computed assessment total to calculate downpayment and installment amounts.

If fee data is wrong:
- payment gate status becomes wrong
- installment statuses become wrong
- cashier display can show the wrong amount due
- overpayment/credit calculations can be misleading

### G) Term parsing is a hard contract
`TermParserUtil.java` is the bridge between registrar term codes and student `SL_*` values.

Risk:
- if registrar changes the code format, enrollment mapping will fail across term resolution, ledger views, and payment history
- even small format drift can break the whole model

## Compatibility Rules To Preserve
The next implementation must preserve these invariants:
- `system_settings.CURRENT_ACADEMIC_TERM` remains the active-term source of truth
- `academic_terms` continues to map cleanly to the registrar term code format
- `SL_*` term-year values remain stable
- shared fee table names and meanings remain stable
- enrollment can still resolve the current term for a student without hardcoded fallbacks
- installment rows remain readable for current and future terms

## What Enrollment Already Provides To The Registrar Redesign
- a term-aware assessment engine
- a payment schedule engine
- term selection and visibility rules
- student-term normalization logic
- installment plan support
- ledger-aware term transitions and balance carry-forward behavior

## What The Next Agent Should Carry Forward
- Keep the registrar active-term contract stable while redesigning term creation
- Do not change term-code semantics unless enrollment is updated in lockstep
- Avoid enabling both fee engines at once unless the migration path is explicit
- Treat installment-plan maintenance as a real feature gap, not just a template detail
- Verify that any registrar term workflow still resolves cleanly through the enrollment term and fee layers

## File References
- [`AcademicTermService.java`](C:/Users/admin/Downloads/6126/projects/enrollment3/src/main/java/com/example/enrollment/service/AcademicTermService.java)
- [`TermContextService.java`](C:/Users/admin/Downloads/6126/projects/enrollment3/src/main/java/com/example/enrollment/service/TermContextService.java)
- [`EnrollmentSettingsService.java`](C:/Users/admin/Downloads/6126/projects/enrollment3/src/main/java/com/example/enrollment/service/EnrollmentSettingsService.java)
- [`FinancialService.java`](C:/Users/admin/Downloads/6126/projects/enrollment3/src/main/java/com/example/enrollment/service/FinancialService.java)
- [`FeeScheduleService.java`](C:/Users/admin/Downloads/6126/projects/enrollment3/src/main/java/com/example/enrollment/service/FeeScheduleService.java)
- [`TermAssessmentService.java`](C:/Users/admin/Downloads/6126/projects/enrollment3/src/main/java/com/example/enrollment/service/TermAssessmentService.java)
- [`TermParserUtil.java`](C:/Users/admin/Downloads/6126/projects/enrollment3/src/main/java/com/example/enrollment/util/TermParserUtil.java)
