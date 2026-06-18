# Fee Import Working Files

Last updated: 2026-06-10

These CSVs support **manual** fee completion when bootstrap did not fully resolve scopes. For normal fresh-PC setup, **`registrar/setup/RUN_FRESH_SETUP.cmd`** should make the active term ready without these files.

**Preferred CSV location:** `registrar/setup/fees/` (e.g. `term-fee-import-template-1120242025.csv`)

**Active term:** `1120242025` (`term_id = 1`)  
**Active programs:** 18 (6 empty programs soft-retired)  
**Scopes per term:** 144 = 18 × 4 years × 2 curriculum slots (S1/S2)

## Files

- `term-fee-import-template-term-1-unresolved.csv`
  - Historical template from term 1 closure work. Regenerate from UI: Registrar → **Program Fees** → **Download CSV template**.
  - Upload via Zone 1 **Or upload completed CSV** on `/admin/term-fees`.

- `term-fee-readiness-term-1-unresolved.csv`
  - Historical diagnostic export. Regenerate from UI: **Export gap list** on Program Fees page.

## Import rules (Registrar Program Fees)

- Each row must identify `program_code`, `year_level`, and `semester` (curriculum slot S1/S2).
- Blank fee cells do not overwrite existing exact rows.
- Primary rate required: `TUITION_PER_UNIT`, `LEC_FEE_PER_UNIT`, or `RLE_FEE_PER_UNIT`.
- If `TUITION_PER_UNIT` is filled and `LEC_FEE_PER_UNIT` is blank, importer copies tuition into lecture rate.
- Negative or non-numeric amounts are rejected for that row.

## Preferred UI workflows (2026-06-09)

| Goal | UI |
|------|-----|
| Copy entire term | Zone 1 **Global import** — source term → target term |
| Fix one program/year/slot | Zone 2 **Scoped import** + edit table |
| Bulk external data | Zone 1 CSV template download → fill → upload |

See `../HANDOFF_UPDATES_20260609.md` for term-fees redesign details.

## Source audit

Demo fee seeds (not production official rates):

- `registrar/db/capss-demo-required/01_setup/03_seed_program_fees_full_lifecycle.sql`
- `registrar/db/demo_scripts/04_demo_fee_rates_two_terms.sql`
- `registrar/docs/demo/presentation/03_TEST_DATA_FEES.sql`
