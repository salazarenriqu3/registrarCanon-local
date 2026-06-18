# CAPSS demo — required SQL (run in order)

All scripts from the **CAPSS Deployment & Demo Manual** fresh-install and panel-demo flow live here.

**Step 0 (once per PC):** run **`../fix`** in MySQL Workbench (parent folder — full schema).

---

## Folder map

| Folder | When | Scripts |
|--------|------|---------|
| **`01_setup/`** | After `db/fix` — run **all 3 in order** | bootstrap → BSIT align → fees |
| **`02_demo_seed_pick_one/`** | Before demo — run **one** file | Maria / Elon / live applicant |
| **`03_grades_maria/`** | During demo (Maria `2026-1001`) | `01` … `08` after each term block enlist |
| **`04_grades_elon_0004/`** | During demo (Elon `2026-0004`) | `01_…_2026-0004` … `08_…` |
| **`05_grades_brent_0002/`** | During demo (Brent `2026-0002`) | `01_…_2026-0002` … `08_…` |
| **`06_reset/`** | Between rehearsal runs | `00_demo_reset.sql` then re-seed |

---

## Quick run order (fresh PC)

| # | File |
|---|------|
| 0 | `../fix` |
| 1 | `01_setup/01_fresh_demo_bootstrap.sql` |
| 2 | `01_setup/02_bsit_full_align_term_and_curriculum.sql` |
| 3 | `01_setup/03_seed_program_fees_full_lifecycle.sql` |
| 4 | **Pick one** in `02_demo_seed_pick_one/` |
| 5 | Build & deploy WARs (see `../../docs/handoff/legacy-capss/01-new-pc/NEW_PC_SETUP.md`) |
| 6+ | Grade scripts from `03_grades_maria/` (or Elon/Brent folder) after each term |

---

## Demo seed options (`02_demo_seed_pick_one/`)

| File | Use for |
|------|---------|
| `demo_full_lifecycle.sql` | Maria Santos `2026-1001` — skip to enrollment demo |
| `demo_elon_2026-0004_fresh.sql` | Elon Musk `2026-0004` — clean finance demo |
| `00_demo_applicant_setup.sql` | Live admission → registrar flow (panel Phases 1–2) |

---

## Other SQL (not in this folder)

Finance QA, BSN lifecycle, legacy repairs, and audits remain in **`../demo_scripts/`**.

Guides: **`../../docs/handoff/legacy-capss/05-demo-guides/README_DEMO_SQL.md`**

Note: run `01_setup/04_seed_demo_it_schedules_and_filter_sections.sql` after the three setup scripts when you want demo-ready IT schedules and cross-program Gen Ed offerings for filter testing.
