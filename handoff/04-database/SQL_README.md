# EAC `eacdb` — SQL inventory (May 2026 unified)

## One script for fresh install

| Order | File | Required |
|-------|------|----------|
| 1 | **`db/fix`** | Yes — full drop/create, seed, cross-system extensions |
| 2 | `db/capss-demo-required/01_setup/01_fresh_demo_bootstrap.sql` | Demo — calendar `academic_terms` + open term |
| 3 | `db/capss-demo-required/01_setup/02_bsit_full_align_term_and_curriculum.sql` | Demo — SET BSIT 48 courses + sections all terms |
| 4 | `db/capss-demo-required/01_setup/03_seed_program_fees_full_lifecycle.sql` | Demo — **required** for cashier totals |
| 5 | `db/capss-demo-required/02_demo_seed_pick_one/demo_full_lifecycle.sql` OR `demo_elon_2026-0004_fresh.sql` OR `00_demo_applicant_setup.sql` | Demo student seed |

**Legacy split (optional — superseded by step 3):** `00_seed_bsit_curriculum_set_official.sql` + `01_seed_bsit_class_sections_demo.sql`

**New PC quick path:** see `handoff/01-new-pc/NEW_PC_SETUP.md`

See **`handoff/05-demo-guides/README_DEMO_SQL.md`** for grade scripts `01`–`08` and Brent/Elon (`2026-0002` / `2026-0004`) variants.

**Do not run** on a fresh PC: files in `db/archive/` (merged into `db/fix`).

For an **existing database** upgraded from before May 27 2026, run once: `db/eacdb_cross_system_schema.sql`

## Demo-only scripts (`db/demo_scripts/`)

| Script | Purpose |
|--------|---------|
| `README_DEMO_SQL.md` | Full execution order and subject counts (10/8/7/6/5/4/2) |
| `00_seed_bsit_curriculum_set_official.sql` | SET BSIT curriculum (replaces BSCS clone / `bsit_curriculum_patch.sql`) |
| `01_seed_bsit_class_sections_demo.sql` | Class sections for block enlist |
| `capss-demo-required/01_setup/03_seed_program_fees_full_lifecycle.sql` | Program fee rows for lifecycle demo |
| `00_demo_applicant_setup.sql` | Applicant `DEMO-SANTOS-001` only (live admission flow) |
| `demo_full_lifecycle.sql` | Pre-built student `2026-1001` + ledger |
| `00_demo_reset.sql` | Wipe Maria between rehearsals |
| `01`–`08_demo_grades_*.sql` | Term grades for Maria (`2026-1001`) |
| `01`–`08_demo_grades_*_2026-0002.sql` | Same for Brent Ramilla |
| `01`–`08_demo_grades_*_2026-0004.sql` | Same for Elon Musk |

## Deprecated (archived — do not use on fresh install)

Moved to **`db/archive/`** — see `db/archive/README.md`:

| File | Reason |
|------|--------|
| `hotfix_*.sql` | Merged into `db/fix` |
| `05_admission_eacdb_align.sql` | Merged into `eacdb_cross_system_schema.sql` |
| `01_schema_eacdb_unified.sql` + `02_seed_*` | Superseded by `db/fix` |
| `enrollment3/bsit_curriculum_patch.sql` | Use `00_seed_bsit_curriculum_set_official.sql` |
| `demo_scripts/fix_student_2026-0028_forward.sql` | Use `00_finance_demo_reset.sql` + `10_seed_finance_demo_personas.sql` |

## Three applications — one database

| App | Context | Schema source |
|-----|---------|----------------|
| **admission.war** | `/admission` | Shared `eacdb`; `users`, `applicants`, `programs.level`, `school_terms` |
| **registrar.war** | `/registrar` | Shared `eacdb`; `grades`, `student_grades` VIEW, VPAA tables |
| **enrollment.war** | `/enrollment` | Shared `eacdb`; `students`, `student_ledger`, `enrollment_settings`, fee tables |

All three use `jdbc:mysql://localhost:3306/eacdb` with `spring.jpa.hibernate.ddl-auto=none`.

## Verify after `db/fix`

```sql
USE eacdb;
SELECT DATA_TYPE FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA='eacdb' AND TABLE_NAME='student_enlistments' AND COLUMN_NAME='student_id';
-- expect: varchar

SELECT program_code, level FROM programs WHERE program_code='BSIT';
-- expect: COLLEGE

SELECT TABLE_TYPE FROM information_schema.TABLES
WHERE TABLE_SCHEMA='eacdb' AND TABLE_NAME='student_grades';
-- expect: VIEW
```
