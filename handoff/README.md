# CAPSS Handoff Documentation

All setup, demo, and agent docs live here — grouped by purpose.

**New PC?** Open **`START_HERE.txt`** or **`01-new-pc/NEW_PC_SETUP.md`**.

---

## Folder map

| Folder | Contents | Start here if… |
|--------|----------|----------------|
| **`01-new-pc/`** | `NEW_PC_SETUP.md` | Setting up on another machine |
| **`02-panel-demo/`** | `CAPSS_Deployment_and_Demo_Manual.md` | Running the full panel demo |
| **`03-agent-dev/`** | `AGENT_HANDOVER_JUN2026.md` — Finance/enrollment sprint (enrollment3 WAR) | Continuing finance / enrollment dev work |
| **`03-agent-dev/`** | `AGENT_HANDOVER_REGISTRAR_UI_FEE_SPRINT.md` — **Fee arch overhaul + full UI migration (registrar WAR)** | Continuing registrar UI or fee settings work |
| **`04-database/`** | `SQL_README.md` | SQL inventory and fresh-install order |
| **`05-demo-guides/`** | Demo SQL order, finance QA, build steps | Demo scripts or billing QA |
| **`06-testing/`** | Test instructions, demo script, production checklist | QA / UAT |
| **`07-legacy/`** | Older handover notes | Historical context only |

---

## SQL files

| Path | Purpose |
|------|---------|
| `../db/fix` | Full schema (step 0 on fresh PC) |
| **`../db/capss-demo-required/`** | **All CAPSS demo scripts** (setup, seeds, grades) — see `RUN_ORDER.txt` |
| `../db/demo_scripts/` | Finance QA, BSN, legacy repair scripts only |

Guide: **`05-demo-guides/README_DEMO_SQL.md`** · **`../db/capss-demo-required/README.md`**

---

## Quick fresh-install order

1. `../db/fix`
2. `../db/capss-demo-required/01_setup/01_fresh_demo_bootstrap.sql`
3. `../db/capss-demo-required/01_setup/02_bsit_full_align_term_and_curriculum.sql`
4. `../db/capss-demo-required/01_setup/03_seed_program_fees_full_lifecycle.sql`
5. One demo seed from `../db/capss-demo-required/02_demo_seed_pick_one/`
6. Build & deploy `enrollment.war`, `registrar.war`, `admission.war`

Details: **`01-new-pc/NEW_PC_SETUP.md`**.

---

## Source code (separate folders)

| Folder | Builds |
|--------|--------|
| `../` (this repo) | `registrar.war` |
| `../../enrollment3/` (sibling on delivery USB) | `enrollment.war` |
| Admission source (e.g. `AdmissionEAC/`) | `admission.war` |
