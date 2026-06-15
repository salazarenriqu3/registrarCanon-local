# Batch 3 Fee Unification Notes

Last updated: 2026-06-07

> **Historical Batch 3 notes.** Unresolved **248-scope** figures are pre-retirement / pre-closure snapshots.  
> **Current:** `HANDOFF_UPDATES_20260609.md`, `READINESS_CLOSURE_20260608.md`, 21 programs / 168 scopes / term 2.

## Policy

Live billing must read fee amounts from exact-scope rows in `program_fee_settings`.

Global `NULL term_id` rows may remain as registrar-admin templates, but they no longer satisfy live assessment reads.

## Code Changes

- Enrollment `FeeScheduleService` no longer uses Java/settings fallbacks for tuition or RLE rates.
- Enrollment `TermAssessmentService` only resolves fees when a student has chargeable units.
- Enrollment `FinancialService` no longer queries legacy `program_fee_rates` for RLE audit snapshots.
- Enrollment settings seed/schema no longer creates `fee_fallback_enabled`, `default_tuition_per_unit`, or `rle_rate_per_hour`.
- Enrollment and registrar `ProgramFeeSettingRepository` now expose exact-scope live lookups.
- Enrollment and registrar `TermFeeAdminService.getFeeRatesForScope` now use exact-scope live lookup.
- Registrar scholar fee calculations now require exact official fee rows for chargeable students.
- Registrar fee preparation no longer creates blank exact rows when a scope has no same-program fallback or template source.
- Registrar fee admin now surfaces term readiness, incomplete exact rows, an unresolved scope queue, and CSV export for manual fee completion.
- Registrar fee admin now exports an import-ready fee CSV and imports completed CSV rows into exact active-term `program_fee_settings`.

## Verification

- `enrollment3` package build passed.
- `registrar` package build passed.
- Database scan showed the active term currently has partial exact fee coverage.
- Database scan showed global fallback rows still exist, but those rows are now template/admin data rather than live billing data.
- Registrar fee preparation ran for active term `1` and completed exact BSIT fee rows from available source data.
- Registrar template-copy ran for active term `1` and completed exact BSCPE fee rows from the BSIT template mapping.
- Active-term exact coverage is now 16 scopes: 8 BSIT scopes and 8 BSCPE scopes.
- The remaining 248 active-term scopes have no usable source rows and were intentionally left unresolved.
- Registrar fee-admin runtime checks passed:
- BSIT year 1 semester 2 showed the exact active-term tuition row.
- BSCPE year 1 semester 2 showed the copied exact active-term tuition row.
- BSCS year 1 semester 1 surfaced missing-rate warnings instead of silently using fallback data.
- Registrar fee-admin runtime checks also confirmed the readiness card renders and the unresolved export downloads as CSV.
- Registrar fee-admin runtime checks confirmed the import template exports 248 unresolved rows.
- Registrar fee-admin runtime checks confirmed a controlled completed CSV upload creates an exact active-term row and reports the import counters.
- The controlled CSV import row was deleted after verification.
- Enrollment cashier runtime check passed with a temporary `B3FEE-BSIT` student; billing calculated from exact active-term `program_fee_settings`.
- The temporary `B3FEE` runtime rows were cleaned after verification.

## Remaining Data Work

Use registrar fee readiness/admin preparation to complete exact fee rows for the active term before live billing.

The active code is intentionally stricter now: missing exact rows should surface as configuration errors rather than silent default charges.

Current data reality:

- BSIT and BSCPE have exact active-term rows.
- All other active programs still need official primary fee values imported or entered.
- The current unresolved import file has `TUITION_PER_UNIT` and `LEC_FEE_PER_UNIT` blank for the remaining 248 scopes; those primary rates must come from registrar-approved fee data.
- The preferred completion workflow is now: download the unresolved import template, fill official fee amounts, upload the completed CSV, then rerun readiness.
- Global `NULL term_id` rows may be used by registrar-admin preparation only; they are not valid live billing rows.

## Hard-Test Follow-Up

- BSIT and BSCPE term `1`, year `1`, semester `1` fee rows had outlier per-unit values that produced inflated runtime assessments.
- The outlier rows were corrected by copying each program's own year `1`, semester `2` exact active-term fee profile into its year `1`, semester `1` row.
- A BSCPE hard-test student then assessed at 24 units x 1,500.00 plus 1,000.00 misc, posted a 3,000.00 downpayment, finalized as Regular, committed 10 subjects, and exported COR successfully.
