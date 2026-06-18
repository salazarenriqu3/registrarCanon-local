# Demo SQL — execution order (SET BSIT + unified finance)

> **CAPSS demo SQL** lives in `registrar/db/capss-demo-required/` (grouped by step). This guide lives in `docs/handoff/legacy-capss/05-demo-guides/`. Finance/BSN/legacy SQL stays in `db/demo_scripts/`.

All scripts target MySQL **`eacdb`**. Run each file in full (Execute All in Workbench).

## Fresh install (recommended)

| Order | Script | Purpose |
|-------|--------|---------|
| 1 | `db/fix` | Full schema (once per machine) |
| 2 | `capss-demo-required/01_setup/01_fresh_demo_bootstrap.sql` | Calendar terms + `CURRENT_ACADEMIC_TERM` |
| 3 | `capss-demo-required/01_setup/02_bsit_full_align_term_and_curriculum.sql` | BSIT 48 courses + sections on all calendar terms |
| 4 | `capss-demo-required/01_setup/03_seed_program_fees_full_lifecycle.sql` | Program fees (calendar `term_code` format) — **required** for cashier totals |

**Admin UI:** `/admin/term-fees` (registrar or enrollment) edits the same `program_general_fees` / `program_specific_fees` rows as step 4 — no extra SQL required.

**Existing DB alignment:** If you are not re-running `db/fix`, run `align_student_enlistments_history_key.sql` once. It removes the old global `UNIQUE(student_id, course_id)` index so historical enlistments can remain readable and later-term retakes are not blocked by schema.

**Optional (legacy alternate schema — skip for standard demo):**

| Script | When you need it |
|--------|------------------|
| `03_fee_term_versioning_schema.sql` | Only if `enrollment.fees.use-program-fee-rates=true` (legacy `program_fee_rates`) |
| `04_demo_fee_rates_two_terms.sql` | Only with step 03 — old fee-rates demo |

## Demo student seed

Run **one** of these from `capss-demo-required/02_demo_seed_pick_one/` after steps 1–4:

| Script | Student |
|--------|---------|
| `demo_full_lifecycle.sql` | Maria `2026-1001` |
| `demo_elon_2026-0004_fresh.sql` | Elon `2026-0004` (clean slate) |
| `00_demo_applicant_setup.sql` | Live admission panel demo |

**Rebuild WARs** after pulling code (registrar term transition + enrollment payment sync). See **`FINANCE_FIX_STEPS.md`** (this folder).

## Registrar academic-term smoke demo

Use **`REGISTRAR_ACADEMIC_TERM_DEMO_MANUAL.md`** after rebuilding registrar when you need to validate:

- active term readiness
- exact-term program fees
- curriculum assignment and program shifts
- term-scoped grading windows
- INC expiration
- registrar-final grade outcomes
- scholarship policy, types, and grants

## Fresh finance QA (Jun 2026 — billing + Student Manager)

Use this **before** a finance demo or after pulling billing fixes. Full steps: **`FRESH_FINANCE_DEMO.md`**.

| Order | Script | Purpose |
|-------|--------|---------|
| 1 | `00_finance_demo_reset.sql` | Remove personas 2026-0026..0028 + bad sync rows |
| 2 | `10_seed_finance_demo_personas.sql` | Juan / John / Jane clean starting states |
| 3 | `11_finance_scenario_checks.sql` | SQL assertions after each UI test |
| 4 | `04_smoke_test_checklist.sql` | System-wide sanity |

| Student | Test |
|---------|------|
| `2026-0028` Juan Dela Cruz | Student Manager **Add** (no blank page) |
| `2026-0027` John Doe | Forward PHP 100 → pay PHP 1 → net **99** |
| `2026-0026` Jane TermTest | Term transition → forward debt **~53074**, not spurious credit |

Does **not** remove Maria (`2026-1001`) or Elon (`2026-0004`).

## Term codes (TermParserUtil)

| Layer | Y1 1st sem A.Y. 2024-2025 |
|-------|---------------------------|
| DB `academic_terms.term_code` | `1120242025` |
| Student `term_year` | `SL_1120242025` |
| Y1 2nd sem | `2120242025` / `SL_2120242025` |

## During demo (per semester)

1. Block enlist in **Enrollment Cashier** (payments via UI — do not INSERT into `payments` alone).
2. **Grade the term** — run the matching grade SQL script **or** enter the same values in Registrar **Faculty → Grade Entry** (see [Grading inputs by lifecycle stage](#grading-inputs-by-lifecycle-stage) below).
3. Verify `graded_subjects` = `enlisted_subjects` in the script output (or Academic History shows all **Passed**).
4. **Registrar** term transition → next `SL_*` term.
5. Repeat.

## Elon Musk `2026-0002` full BSIT grade seeds

Run each script only after Elon is block-enlisted/finalized for that matching term:

| Order | Script | Term | Expected subjects |
|-------|--------|------|-------------------|
| 1 | `01_demo_grades_y1s1_2026-0002.sql` | Y1 S1 / `BSIT-1-1-A` | 10 |
| 2 | `02_demo_grades_y1s2_2026-0002.sql` | Y1 S2 / `BSIT-1-2-A` | 8 |
| 3 | `03_demo_grades_y2s1_2026-0002.sql` | Y2 S1 / `BSIT-2-1-A` | 7 |
| 4 | `04_demo_grades_y2s2_2026-0002.sql` | Y2 S2 / `BSIT-2-2-A` | 6 |
| 5 | `05_demo_grades_y3s1_2026-0002.sql` | Y3 S1 / `BSIT-3-1-A` | 6 |
| 6 | `06_demo_grades_y3s2_2026-0002.sql` | Y3 S2 / `BSIT-3-2-A` | 5 |
| 7 | `07_demo_grades_y4s1_2026-0002.sql` | Y4 S1 / `BSIT-4-1-A` | 4 |
| 8 | `08_demo_grades_y4s2_2026-0002.sql` | Y4 S2 / `BSIT-4-2-A` | 2 |

Lifecycle rhythm:

`block enlist/finalize term` → `pay/test ledger` → `grade term (SQL or faculty UI)` → `Registrar term transition` → repeat.

## Grading inputs by lifecycle stage

Use these **after block enlist** for each term. Columns: **Prelim / Midterm / Final / Semestral (point grade)**. All rows end with status **Passed**.

> **Script naming:** Maria `2026-1001` uses `01_demo_grades_y1s1.sql` … `08_demo_grades_y4s2.sql`. Elon `2026-0002` / `2026-0004` use the same files with `_2026-0002` or `_2026-0004` suffix.

### Y1 S1 — `BSIT-1-1-A` (10 subjects)

**Script:** `01_demo_grades_y1s1*.sql` | **Graded on:** 2025-12-15

| Course | Prelim | Midterm | Final | Semestral |
|--------|--------|---------|-------|-----------|
| AUS0 11 | 90 | 88 | 92 | 1.25 |
| ARPH 11 | 85 | 87 | 89 | 1.50 |
| SMMW 11 | 84 | 86 | 88 | 1.75 |
| AHU1 11 | 88 | 89 | 90 | 1.50 |
| ASS1011 | 83 | 85 | 87 | 2.00 |
| PE1 11 | 90 | 91 | 92 | 1.25 |
| ANS1 11 | 87 | 88 | 89 | 1.50 |
| AECO 11 | 86 | 87 | 88 | 1.75 |
| UCO1 11 | 84 | 86 | 88 | 1.75 |
| UPR1 11 | 80 | 83 | 85 | 2.00 |

### Y1 S2 — `BSIT-1-2-A` (8 subjects)

**Script:** `02_demo_grades_y1s2*.sql` | **Graded on:** 2026-05-15

| Course | Prelim | Midterm | Final | Semestral |
|--------|--------|---------|-------|-----------|
| AET0 12 | 87 | 89 | 91 | 1.50 |
| ANS2 12 | 85 | 86 | 88 | 1.75 |
| APC0 12 | 85 | 87 | 89 | 1.75 |
| PE2 12 | 90 | 91 | 92 | 1.25 |
| SMST012 | 84 | 86 | 88 | 1.75 |
| UADET 32 *or* ACW0 12 | 86 | 88 | 90 | 1.75 |
| UHC1 11 | 82 | 84 | 86 | 2.00 |
| UPR2 12 | 88 | 90 | 92 | 1.50 |

### Y2 S1 — `BSIT-2-1-A` (7 subjects)

**Script:** `03_demo_grades_y2s1*.sql` | **Graded on:** 2026-12-15

| Course | Prelim | Midterm | Final | Semestral |
|--------|--------|---------|-------|-----------|
| AHU2 21 | 88 | 89 | 91 | 1.50 |
| ASS6 21 | 86 | 88 | 90 | 1.75 |
| PE3 21 | 90 | 91 | 92 | 1.25 |
| BEC0 12 | 84 | 86 | 88 | 1.75 |
| UPR3 21 | 87 | 89 | 91 | 1.50 |
| UDM0 21 | 83 | 85 | 87 | 2.00 |
| UIM0 12 | 85 | 87 | 89 | 1.75 |

### Y2 S2 — `BSIT-2-2-A` (6 subjects)

**Script:** `04_demo_grades_y2s2*.sql` | **Graded on:** 2027-05-15

| Course | Prelim | Midterm | Final | Semestral |
|--------|--------|---------|-------|-----------|
| STS0 22 | 86 | 88 | 90 | 1.75 |
| PE4 22 | 91 | 92 | 93 | 1.25 |
| AEN4 22 | 84 | 86 | 88 | 1.75 |
| UNW122 | 87 | 89 | 91 | 1.50 |
| UDS022 | 85 | 87 | 89 | 1.75 |
| UDB122 | 86 | 88 | 90 | 1.75 |

### Y3 S1 — `BSIT-3-1-A` (6 subjects)

**Script:** `05_demo_grades_y3s1*.sql` | **Graded on:** 2027-12-15

| Course | Prelim | Midterm | Final | Semestral |
|--------|--------|---------|-------|-----------|
| SMA3 21 | 85 | 87 | 89 | 1.75 |
| USI1 31 | 86 | 88 | 90 | 1.75 |
| UNW2 31 | 87 | 89 | 91 | 1.50 |
| UEL2 31 | 84 | 86 | 88 | 1.75 |
| UEL131 | 88 | 90 | 92 | 1.50 |
| UDB231 | 86 | 88 | 90 | 1.75 |

### Y3 S2 — `BSIT-3-2-A` (5 subjects)

**Script:** `06_demo_grades_y3s2*.sql` | **Graded on:** 2028-05-15

| Course | Prelim | Midterm | Final | Semestral |
|--------|--------|---------|-------|-----------|
| UADET 32 | 88 | 90 | 92 | 1.50 |
| UEDP0 32 | 86 | 88 | 90 | 1.75 |
| UIAS1 32 | 87 | 89 | 91 | 1.50 |
| UQM0 32 | 84 | 86 | 88 | 1.75 |
| USPI 32 | 85 | 87 | 89 | 1.75 |

### Y4 S1 — `BSIT-4-1-A` (4 subjects)

**Script:** `07_demo_grades_y4s1*.sql` | **Graded on:** 2028-12-15

| Course | Prelim | Midterm | Final | Semestral |
|--------|--------|---------|-------|-----------|
| UCP1 41 | 88 | 90 | 92 | 1.50 |
| UIAS2 41 | 87 | 89 | 91 | 1.50 |
| USAM0 41 | 86 | 88 | 90 | 1.75 |
| USI1 41 | 88 | 90 | 92 | 1.50 |

### Y4 S2 — `BSIT-4-2-A` (2 subjects — graduation term)

**Script:** `08_demo_grades_y4s2*.sql` | **Graded on:** 2029-05-15

| Course | Prelim | Midterm | Final | Semestral |
|--------|--------|---------|-------|-----------|
| UCP2 42 | 89 | 91 | 93 | 1.25 |
| UOJT 42 | 92 | 93 | 94 | 1.25 |

### Manual faculty entry (alternative to SQL)

If demonstrating live grade encoding instead of SQL:

1. **Registrar** → login `prof / 1234` → **My Classes** → open the block section (e.g. `BSIT-1-1-A`).
2. For each enlisted student, enter **Prelim**, **Midterm**, and **Final** from the table above.
3. Save — the system computes semestral grade and **Passed** status automatically.
4. Confirm in **Student Manager → Academic History**.

## Official subject counts (BSIT)

| Term | Subjects |
|------|----------|
| Y1S1 | 10 |
| Y1S2 | 8 |
| Y2S1 | 7 |
| Y2S2 | 6 |
| Y3S1 | 6 |
| Y3S2 | 5 |
| Y4S1 | 4 |
| Y4S2 | 2 |

## Marian BSN lifecycle test data

For a BSN student full lifecycle test, run these after the fresh install scripts:

| Order | Script | Purpose |
|-------|--------|---------|
| 1 | `00_seed_bsn_curriculum_marian_official.sql` | Seeds/activates the Marian BSN official curriculum |
| 2 | `01_seed_bsn_class_sections_demo.sql` | Opens `BSN-{Y}-{S}-A` sections on all calendar terms and inserts schedules |
| Per term | `02_demo_bsn_grades_current_term.sql` | Seeds passing grades for the BSN student's current `BSN-Y-S-A` block before term transition |

Expected BSN curriculum slices:

| Term | Subjects | Units |
|------|----------|-------|
| Y1S1 | 9 | 28 |
| Y1S2 | 8 | 27 |
| Y2S1 | 7 | 29 |
| Y2S2 | 6 | 26 |
| Y3S1 | 4 | 25 |
| Y3S2 | 6 | 26 |
| Y4S1 | 3 | 21 |
| Y4S2 | 4 | 20 |

BSN lifecycle rhythm:

`create/approve BSN student` → `block enlist BSN-{Y}-{S}-A` → `pay/test ledger` → grade term → `Registrar term transition` → repeat.

### BSN grading (all terms)

**Script:** `02_demo_bsn_grades_current_term.sql` (set `@student_id` first).

The script auto-detects the student's current `BSN-{Y}-{S}-A` section and seeds **Passed** grades for every enlisted course. Score pattern (by row order in course code):

| Component | Formula / pattern |
|-----------|-------------------|
| Prelim | 84–90 (84 + row# mod 7) |
| Midterm | 86–92 (86 + row# mod 7) |
| Final | 88–94 (88 + row# mod 7) |
| Semestral | Rotates 1.25 → 1.50 → 1.75 → 2.00 → 2.25 |

**Per-term checklist:**

| Term | Section | Subjects | Units |
|------|---------|----------|-------|
| Y1 S1 | BSN-1-1-A | 9 | 28 |
| Y1 S2 | BSN-1-2-A | 8 | 27 |
| Y2 S1 | BSN-2-1-A | 7 | 29 |
| Y2 S2 | BSN-2-2-A | 6 | 26 |
| Y3 S1 | BSN-3-1-A | 4 | 25 |
| Y3 S2 | BSN-3-2-A | 6 | 26 |
| Y4 S1 | BSN-4-1-A | 3 | 21 |
| Y4 S2 | BSN-4-2-A | 4 | 20 |

After each run, confirm `graded_subjects` = `enlisted_subjects` in the script output before triggering term transition.

## Reset between runs

| Goal | Script |
|------|--------|
| Finance QA personas (0026–0028) | `00_finance_demo_reset.sql` → `10_seed_finance_demo_personas.sql` |
| Maria lifecycle | `00_demo_reset.sql` → `demo_full_lifecycle.sql` |
| Elon | Delete `2026-0004` rows → `demo_elon_2026-0004_fresh.sql` |

See **`FRESH_FINANCE_DEMO.md`** for finance retest steps.

## Deprecated / legacy only

| Script | Note |
|--------|------|
| `fix_elon_2026-0004_finance_step_by_step.sql` | Repair corrupted ledger; not for fresh DB |
| `fix_elon_2026-0002_forward.sql`, `fix_zuckerberg_2026-0005_forward.sql`, `fix_spurious_forward_after_drop.sql` | Legacy data repair only — skip on fresh PC |
| `audit_*.sql` | Read-only debug — optional |
| Finance reset + seed | `00_finance_demo_reset.sql` + `10_seed_finance_demo_personas.sql` (replaces old per-student forward fix scripts) |
| `enrollment3/bsit_curriculum_patch.sql` | Do not use |
| Per-slot term codes `1220242025` | Replaced by calendar `1120242025` |

## Canonical curriculum docx

`enrollment3/src/main/resources/curriculums/School of Engineering and Technology/SET BSIT.docx`
