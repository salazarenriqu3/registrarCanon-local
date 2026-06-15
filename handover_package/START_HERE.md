# Registrar Subsystem — Handover Package
## What to read, in what order

This folder contains everything a new agent needs to continue work on the
**EAC Registrar WAR** (`registrar/` → port 8083, context `/registrar`).

---

## Read In This Order

### 1. `AGENT_HANDOVER_REGISTRAR_UI_FEE_SPRINT.md` ← START HERE
The primary handover document for this project's most recent sprint.  
Covers, in full technical detail:
- System topology (port, DB, run commands)
- Java package map
- Fee architecture overhaul — `program_fee_settings` unified table, fallback query, `KNOWN_FEES` registry, every public method of `TermFeeAdminService`
- Critical rules (what to never duplicate, never skip)
- UI layout standard — the canonical Thymeleaf wrapper pattern every page must follow
- All pages migrated + `activeLink` key table
- Bug fixes made (`ClassSchedule @Transient`, `is_active == 1` SpEL)
- Scope boundaries (Basic Ed removed, payments deprecated)
- Known open issues with specific descriptions
- Safe testing procedure

### 2. `AGENT_HANDOVER_JUN2026.md`
Covers the **companion finance sprint** in `enrollment3/` (enrollment WAR).  
Read this for context on: term-close formula, forward balance (net vs. gross), drop/refund logic, and what's still broken (historical ledger mismatch).  
You don't need to touch `enrollment3/` unless the user explicitly asks.

### 3. `BUSINESS_LOGIC_MASTER.md`
Living document — every business logic decision recorded with its rationale.  
Use this to understand *why* things are the way they are before changing them.  
Phases 1–4 = Fee Architecture. Phase 5 = Scope Reduction. Phase 7 = UI Overhaul.

---

## Source Files Included

These are the key source files most likely to need modification by the next agent.
They are copies of the files as they exist after this sprint — treat them as the current ground truth.

| File | What It Is |
|------|-----------|
| `application.properties` | Spring Boot config: port 8083, context `/registrar`, DB `eacdb`, JPA DDL = none |
| `ProgramFeeSetting.java` | JPA `@Entity` for `program_fee_settings`; `getFee()`/`setFee()` dispatch on fee code strings |
| `ProgramFeeSettingRepository.java` | Spring Data repo; `findBestMatch` is the canonical fee read path |
| `TermFeeAdminService.java` | All fee business logic; `KNOWN_FEES` registry; the only place allowed to query `program_fee_settings` |
| `layout.html` | Thymeleaf fragment file — defines `head`, `topbar`, `sidebar(activeLink)` fragments used by every page |
| `theme-eac.css` | Complete CSS design system — all CSS variables, layout classes, component styles |
| `ClassSchedule.java` | JPA entity for `class_schedules`; note `courseCode` is `@Transient` (not mapped to DB) |
| `schema_migration_001.sql` | SQL migration script with the `program_fee_settings` DDL and related schema changes |

---

## Reference / Context Files

| File | What It Is |
|------|-----------|
| `HANDOFF_INDEX.md` | Master index of the `handoff/` directory tree in the full project |
| `SETUP_AND_DEMO_MANUAL.md` | How to set up the project on a fresh machine and run the CAPSS demo |

---

## What You Do NOT Have Here

These exist in the full project repo but were not copied here:
- All other Java source files (`ScholarEnrollmentService.java`, `AcademicGradingService.java`, etc.) — get them from the full repo
- All Thymeleaf templates except `layout.html` — get them from `src/main/resources/templates/`
- The full SQL database dumps / demo scripts — see `db/capss-demo-required/` and `handoff/04-database/`

---

*Handover generated: 2026-06-05*
