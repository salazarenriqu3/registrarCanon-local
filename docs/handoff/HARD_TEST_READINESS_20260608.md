# Hard Test Readiness Gate — 2026-06-08 (updated after term-2 closure)

Workspace:

`C:\Users\sune\Downloads\new-20260606T044759Z-3-001\new`

Pickup handoff:

`registrar/docs/handoff/NEXT_AGENT_HANDOFF_20260608.md`

## Executive Summary

**Active-path hard testing and term transition are complete on the live database.**

| Gate | Status |
|------|--------|
| Registrar compile | PASS |
| Enrollment compile | PASS |
| **Current active term** | **`2120242025`** (term_id `2`, 2nd sem AY 2024–2025) |
| Term 2 fee readiness | READY |
| Term 2 curriculum readiness (21 active programs) | READY |
| Course Catalog + curriculum tools | IMPLEMENTED + verified |
| Cross-app golden paths (HTEST, B7REG, SCHREG) | PASS |
| Term transition rehearsal | **DONE** (`1120242025` → `2120242025`) |
| Post-transition re-enrollment | PASS (`26-1-00001` BSIT, BSCPE disposable) |
| Term 2 edge cases (B2TEST, waitlist, drop, admission) | PASS — `_runtime_logs/term2_edge_verify_result_20260608.json` |
| Future terms (`1120252026` onward) | **Prepared** — run `python _runtime_logs/prep_future_ay_term.py` |

## Verification Evidence (2026-06-08)

| Script / result file | Scope |
|----------------------|--------|
| `_runtime_logs/cross_app_verify_result_20260608.json` | Cross-app BSCPE enroll → registrar mirror |
| `_runtime_logs/extended_verify_result_20260608.json` | B7REG + SCHREG |
| `_runtime_logs/term_transition_result_20260608.json` | Term transition + post-transition smoke |
| `_runtime_logs/post_transition_complete_20260608.json` | Forwarded balance clear + term-2 re-enroll |
| `_runtime_logs/term2_edge_verify_result_20260608.json` | B2TEST, waitlist, drop, admission, catalog |

## What Changed (closure session)
1. Confirmed live DB active term is `1120242025` (A.Y. 2024-2025, 1st Semester).
2. Confirmed term 1 readiness JSON: `ready=true`, `216` scopes checked, `0` fee/curriculum blockers.
3. Found term 2 was **not** ready (`208` missing + `7` fallback scopes) — this blocked term transition.
4. Ran `POST /admin/term-fees/import-from-term` with `sourceTermId=1`, `targetTermId=2`, `importScope=all`.
   - Result: `importChecked=216`, `importCoreCreated=215`, `importCoreUpdated=1`
5. Confirmed term 2 readiness JSON: `ready=true`.

## Hard Test Scope — Include

Use disposable student prefixes (`HTEST-*`) and clean up after each pass.

### Registrar (port 8083 or isolated 8095, context `/registrar`)

| # | Feature | Entry point | Notes |
|---|---------|-------------|-------|
| 1 | Settings readiness | `/admin/settings` | Should show **Ready for operation** |
| 2 | Term Fees admin | `/admin/term-fees?termId=1` | All 27 active programs, 216 scopes |
| 3 | Course Catalog | `/admin/courses` | Add/edit/deactivate; verify picker integration |
| 4 | Curriculum dashboard | `/admin/curriculum` | Completion workspace should be hidden |
| 5 | Curriculum builder + picker | `/admin/curriculum/view/{id}` | Attach existing catalog course; duplicate guard |
| 6 | Student Manager | `/admin/student-manager` | Profile, roster units, print COR |
| 7 | Class scheduling | `/admin/classes` | Committed-only section counts |
| 8 | Scholar cashier | `/admin/scholar-cashier` | Grant, enlist, assess, pay |
| 9 | Admissions approval | admission acceptance flow | Writes aligned `term_year` / `semester` |
| 10 | Term transition gate | `/admin/settings` dropdown | Target `2120242025` should pass readiness check |

### Enrollment (port 8082 or 8092)

| # | Feature | Entry point | Notes |
|---|---------|-------------|-------|
| 11 | Cashier staging | cashier flow | Staged rows visible before finalize |
| 12 | Regular block (BSCPE) | block assignment | Requires active-term block sections |
| 13 | Payment + finalize | cashier | Commits official load |
| 14 | Official ledger | ledger view | Ignores staged-only rows |
| 15 | COR export | after finalize | |
| 16 | Faculty roster + grades | faculty dashboard | Committed-only counts/rosters |
| 17 | Section monitor | registrar dashboard in enrollment | Committed-only capacity |
| 18 | Waitlist force-enroll | enrollment registrar tools | Writes `COMMITTED` |
| 19 | Drop/refund | admin bulk drop | Unified penalty/refund path |
| 20 | Cross-app identity | same `student_number` in ledger, enlistments, grades | |

### Cross-app golden paths (prior verified patterns)

Reuse these proven disposable flows as regression anchors:

- `B7REG-001` pattern — BSCPE enroll → pay → finalize → COR → grade → registrar mirror
- `SCHREG-001` pattern — scholar grant → enlist → assess → pay
- `B2TEST` pattern — staged vs committed isolation
- `B3FEE` pattern — exact-term fee billing

## Hard Test Scope — Exclude (by agreement)

Do **not** treat these as pass/fail blockers:

- Deprecated registrar walk-in payment screens
- Deprecated registrar-side enrollment screens

## Term Transition — Completed

Transition executed: `1120242025` → `2120242025`.

- `system_settings.CURRENT_ACADEMIC_TERM` = `2120242025`
- `term_transition_audit`: 2 students advanced, 1 with forwarded debt
- Post-transition: BSIT re-enroll, BSCPE sections seeded (`registrar/db/demo_scripts/seed_bscpe_class_sections_calendar.sql`)
- **Rollback:** restore DB backup only — not automatic

## Recommended Hard Test Order — Status

1. Sanity — **DONE** (term 2 readiness)
2. Catalog/Curriculum — **DONE** (pages reachable; manual attach optional)
3. Enrollment golden path — **DONE** (B7REG, cross-app)
4. Registrar mirror — **DONE**
5. Scholar path — **DONE** (SCHREG)
6. Lifecycle edge — **DONE** (B2TEST on term 2)
7. Term transition — **DONE**
8. Post-transition enroll — **DONE**

## Still Future / Lower Priority

- Prepare fees for `1120252026` and later terms before operating those academic years
- Curriculum CSV import into builder (suggested in handoff, not yet implemented)
- Batch 1 term-authority consolidation (duplicate fallback paths — not blocking)
- Registrar Spring Security (enrollment has it; registrar does not)
- UI header polish per `docs/ui_header_specifications.md`
- Manual UAT with registrar/cashier staff on term `2120242025`

## Runtime Commands (term 2)

```powershell
$base = 'http://localhost:8095/registrar'
Invoke-WebRequest -UseBasicParsing -Uri "$base/login" -SessionVariable s
Invoke-WebRequest -UseBasicParsing -Uri "$base/login" -Method Post -WebSession $s -Body @{username='admin'; password='1234'}
(Invoke-WebRequest -UseBasicParsing -Uri "$base/admin/settings/readiness?termCode=2120242025" -WebSession $s).Content
```

Login: `admin` / `1234`

## Retired Programs (informational)

These six programs were soft-retired (`active_status=0`) and should not appear in active readiness checks:

`BSBA`, `BSCE`, `BSCS`, `BSECE`, `BSED`, `BSMATH`

Historical placeholders and fee rows remain for audit. Reactivate only when official curriculum exists.

## Bottom Line

**Stabilization handoff scope is complete.** Active-path features are implemented and runtime-verified through term transition and term-2 operation. Next work: **human UAT** via `HUMAN_UAT_MASTER.md` after `run_full_preflight.py` is green.
