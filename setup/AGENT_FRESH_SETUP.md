# Agent Playbook — Fresh Machine Setup

Last updated: 2026-06-09  
**Audience:** Cursor agents, devops, anyone provisioning a demo PC from scratch.

**Canonical project root:** folder containing `registrar/` and `enrollment3/`  
Example: `C:\Users\sune\Downloads\new`

**Human + demo companion:** `registrar/handoffNew/COMPLETE_FRESH_SETUP_AND_DEMO_GUIDE.md`

---

## Agent mission

1. Verify prerequisites (JDK, MariaDB, Maven, project files).
2. Run **one bootstrap** that seeds **everything** needed for demo/UAT.
3. Start Registrar + Enrollment.
4. Confirm Settings readiness green for **`1120242025`** (2425 1st sem).

**Do not** hand-edit scattered SQL unless bootstrap fails on a specific step — fix that step, re-run bootstrap.

---

## Phase 0 — Prerequisite check (run first)

From **project root**:

```cmd
registrar\setup\CHECK_PREREQUISITES.cmd
```

Or PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File registrar\setup\CHECK_PREREQUISITES.ps1
```

### Required checks (must PASS)

| ID | What | If FAIL |
|----|------|---------|
| `PRJ-*` | Project folders + bootstrap script exist | Wrong working directory; clone/copy full repo |
| `JDK` | Java **17+** on PATH | Install JDK 17 or 21; add `java` to PATH |
| `MAVEN` | `mvn` or `enrollment3\mvnw.cmd` | Install Maven 3.6+ |
| `MYSQL-CLIENT` | `mysql.exe` found | Install MariaDB/MySQL; add `bin` to PATH |
| `MARIADB-SERVICE` | Server reachable `127.0.0.1:3306` as `root` | Start MariaDB service; fix password in `application.properties` if not empty |

### Informational (bootstrap still OK)

| ID | Notes |
|----|--------|
| `DB-EACDB` | Existing `eacdb` is **dropped** by bootstrap |
| `PORT-*` | Ports 8082/8083 in use → apps may already be running |
| `PYTHON-OPTIONAL` | Only needed for automated preflight scripts |

### Default DB credentials (both apps)

| Setting | Value |
|---------|--------|
| Host | `127.0.0.1:3306` |
| Database | `eacdb` |
| User | `root` |
| Password | *(empty)* |

If password is not empty, update:

- `registrar/src/main/resources/application.properties`
- `enrollment3/src/main/resources/application.properties`

and re-run `CHECK_PREREQUISITES.ps1` with `-DbPassword "yourpass"`.

---

## Phase 1 — Full bootstrap (seeds everything)

```cmd
registrar\setup\RUN_FRESH_SETUP.cmd
```

**Destructive:** drops and recreates `eacdb`. Runtime ~10–20 minutes (curriculum seed is longest).

### What gets seeded (complete list)

See **`BOOTSTRAP_SEED_MANIFEST.md`** in this folder for step-by-step file list.

Summary:

| Area | Seeded? |
|------|---------|
| Schema (`eacdb`) | Yes — `registrar/db/fix` |
| Enlistment lifecycle columns | Yes — enrollment SQL patch |
| Full curriculum (21 programs) | Yes |
| Calendar terms 2425–2728 (S1+S2) | Yes |
| Demo program fees (global templates) | Yes |
| `program_fee_settings` migration | Yes |
| Retired empty programs (6) | Yes |
| **Block sections all calendar terms** | Yes |
| **Block offerings + block_id links** | Yes |
| **IRREG-A irregular sections** | Yes |
| **Faculty + grading windows FORCE_OPEN** | Yes |
| **Class schedules (not TBA)** | Yes |
| Active term **1120242025** | Yes |
| Exact fees term 1 + **all calendar terms** | Yes |
| **prof.cruz** on all active-term sections | Yes |
| Finance gates + installment plan | Yes (in schema seed) |
| Verify SQL report | Yes — last step |

**Active term after bootstrap:** `1120242025` · `term_id = 1` · Y1 block **`BSCPE-1-1-A`**

### Bootstrap success criteria (SQL output)

Last step should show roughly:

- `CURRENT_ACADEMIC_TERM` = `1120242025`
- `FEE GAPS active term` → `unresolved = 0`
- `UNSCHEDULED active term` → `0` (or very low)
- `BLOCK OFFERINGS active term` → **> 0**
- `PROF CRUZ SECTIONS active term` → **> 0**
- Each row in `SECTIONS BY CALENDAR TERM` → block_sections **> 0**, irreg_sections **> 0**

If `FEE GAPS` > 0: upload `registrar/setup/fees/term-fee-import-template-1120242025.csv` via Program Fees UI.

---

## Phase 2 — Start applications

**Terminal 1 — Registrar** (Java 17):

```cmd
cd registrar
mvn -q spring-boot:run
```

Wait for `Started RegistrarApplication`.  
URL: http://localhost:8083/registrar/login

**Terminal 2 — Enrollment** (Java 21):

```cmd
cd enrollment3
mvn -q spring-boot:run
```

URL: http://localhost:8082/login

### Agent verify (HTTP)

| URL | Expect |
|-----|--------|
| http://localhost:8083/registrar/login | 200, login page |
| http://localhost:8082/login | 200, login page |

Login **`admin` / `1234`** on both.

---

## Phase 3 — UI smoke (agent or human)

| Step | URL | Pass when |
|------|-----|-----------|
| 1 | http://localhost:8083/registrar/admin/settings | Active term **1120242025**, readiness **Ready** |
| 2 | http://localhost:8083/registrar/admin/term-fees?termId=1 | No fee blockers |
| 3 | http://localhost:8083/registrar/admin/finance-policy | Gates editable |
| 4 | http://localhost:8083/registrar/admin/classes | BSCPE sections have times |
| 5 | http://localhost:8083/registrar/admin/class-scheduling?termId=1 | Blocks + IRREG-A visible |
| 6 | http://localhost:8082/admin/cashier | Cashier loads |

Full checklist: **`registrar/handoffNew/HUMAN_UAT_CHECKLIST.md`** Session 0.

---

## Phase 4 — Demo docs (human)

| Doc | Use |
|-----|-----|
| `HUMAN_UAT_CHECKLIST.md` | Session sign-off |
| `THREE_TRACK_LIFECYCLE_DEMO_MANUAL.md` | Y1→Y4 + transferee + shift + grades |

---

## Troubleshooting (agent actions)

| Symptom | Action |
|---------|--------|
| `mysql` not found | Install MariaDB; add `C:\Program Files\MariaDB 10.x\bin` to PATH |
| Connection refused 3306 | `services.msc` → start MariaDB |
| Access denied for root | Set password in properties; pass `-DbPassword` to prereq script |
| Bootstrap fails on step 3 (curriculum) | Wait — file is huge; ensure disk space; re-run |
| Bootstrap fails collation error | Report step name; may need MariaDB 10.4+ |
| Readiness not green | Re-run `setup/sql/02` and `05` in Workbench; or CSV upload |
| Sections TBA | Re-run `registrar/db/seed_all_class_schedules.sql` then `setup/sql/03` |
| Enrollment enlistment_status error | Re-run `enrollment3/.../01_enlistment_status_schema.sql`; **restart Enrollment** |
| Port 8083 in use | Stop other Tomcat/Java; `netstat -ano \| findstr :8083` |
| Registrar password reset weirdness | `RegistrarApplication` resets admin/prof to 1234 on start (demo only) |

---

## Agent command cheat sheet

```cmd
REM 0. Prerequisites
registrar\setup\CHECK_PREREQUISITES.cmd

REM 1. Bootstrap (from project root)
registrar\setup\RUN_FRESH_SETUP.cmd

REM 2. Compile check (optional)
cd registrar && mvn -q -DskipTests compile
cd ..\enrollment3 && mvn -q -DskipTests compile

REM 3. Apps (two terminals)
cd registrar && mvn -q spring-boot:run
cd enrollment3 && mvn -q spring-boot:run
```

---

## Files in `registrar/setup/`

| File | Purpose |
|------|---------|
| **`AGENT_FRESH_SETUP.md`** | This playbook |
| **`BOOTSTRAP_SEED_MANIFEST.md`** | Full seed inventory |
| **`CHECK_PREREQUISITES.cmd`** | Machine prereq gate |
| **`RUN_FRESH_SETUP.cmd`** | One-shot bootstrap |
| `sql/01` … `05` | Term, fees, prof.cruz, verify |
| `fees/` | CSV templates |

---

## Out of scope for bootstrap

- Production official fee rates (demo amounts only)
- TOR PDF / OCR
- Six retired programs without curriculum files (BSBA, BSCE, BSCS, BSECE, BSED, BSMATH) — intentionally inactive
- Python preflight (optional; not required for setup)
