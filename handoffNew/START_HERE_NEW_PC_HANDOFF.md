# START HERE — New PC Handoff

Last updated: 2026-06-10  

**Read this first on a fresh machine:**

→ **`PROJECT_STATUS_AND_ROADMAP.md`** — what's done, sidetracks, UAT progress, what's pending  
→ **`COMPLETE_FRESH_SETUP_AND_DEMO_GUIDE.md`** — setup commands, agent handoff, demo instructions  

Then **`HANDOFF_UPDATES_20260609.md`** (changelog). Full UAT detail: **`MASTER_DEMO_UAT_MANUAL.md`**.

---

## What you are deploying

| Component | Folder | URL (dev) |
|-----------|--------|-----------|
| **Registrar** | `registrar/` | http://localhost:8083/registrar |
| **Enrollment / Cashier** | `enrollment3/` | http://localhost:8082 |
| **Database** | MariaDB `eacdb` | `127.0.0.1:3306` |

Both apps share one database. Active test term: **`1120242025`** (A.Y. 2024–25, **1st sem**).

---

## What to copy to the new PC

Copy the **entire project folder**, e.g.:

```text
C:\Users\<you>\Downloads\new-20260606T044759Z-3-001\new
```

You need:

- `registrar/` — Registrar app + SQL seeds
- `enrollment3/` — Enrollment app
- `registrar/handoffNew/` — this handoff + master manual
- `registrar/db/` — bootstrap SQL

You do **not** need:

- Old Tomcat dumps or WAR backups
- Old `eacdb` database dumps (bootstrap SQL rebuilds everything)
- Cursor chat history or `_runtime_logs` test output (optional to keep)

---

## Software to install (new PC)

| Software | Version | Notes |
|----------|---------|-------|
| **JDK** | 17 or 21 | Add `java` to PATH |
| **MariaDB** or **MySQL** | 10.4+ / 8.0+ | Port **3306**, user **`root`**, password **empty** (default in config) |
| **Maven** | 3.6+ | Or use `enrollment3\mvnw.cmd` |
| **MySQL Workbench** | any | Recommended for running SQL |

Verify in a terminal:

```text
java -version
mysql --version
mvn -version
```

**Optional:** Python 3.10+ — only if you want automated preflight scripts later. **Not required** for setup or manual UAT.

---

## New PC setup — do in this order

### Step 0 — Prerequisites (agents: read this first)

**Agent playbook:** `registrar/setup/AGENT_FRESH_SETUP.md`

```cmd
registrar\setup\CHECK_PREREQUISITES.cmd
```

Checks: JDK 17+, Maven, MariaDB running, project folders, ports.

### Step 1 — Install MariaDB and start the service

Default expected by both apps:

| Setting | Value |
|---------|-------|
| Host | `127.0.0.1:3306` |
| Database | `eacdb` (created by bootstrap) |
| User | `root` |
| Password | *(empty)* |

If your root password is not empty, edit:

- `registrar/src/main/resources/application.properties`
- `enrollment3/src/main/resources/application.properties`

---

### Step 2 — Bootstrap the database (SQL only)

```cmd
registrar\setup\RUN_FRESH_SETUP.cmd
```

Runs prerequisite check, then **17 seed steps** (see `registrar/setup/BOOTSTRAP_SEED_MANIFEST.md`).

Legacy path `registrar\db\run_full_uat_bootstrap.cmd` calls the same script.

**Or Workbench** — open and Execute each file in order (see list in `MASTER_DEMO_UAT_MANUAL.md` Part 2B, steps 1–10).

**Or mysql CLI** (from project root):

```text
mysql -u root < registrar/db/00_full_uat_bootstrap.sql
```

Wait until it finishes. Step 2 (`04_seed_full_curriculum.sql`) is the longest.

---

### Step 3 — Start both applications

**Terminal 1 — Registrar:**

```text
cd registrar
mvn -q spring-boot:run
```

Wait for `Started RegistrarApplication`.  
Open: http://localhost:8083/registrar/login

**Terminal 2 — Enrollment:**

```text
cd enrollment3
mvn -q spring-boot:run
```

Open: http://localhost:8082/login

First run may take a few minutes while Maven downloads dependencies.

---

### Step 4 — Verify readiness (Registrar UI)

1. Login: **admin** / **1234**
2. Go to **Settings**: http://localhost:8083/registrar/admin/settings
3. Confirm active term = **`1120242025`**
4. Readiness card should show **Ready for operation**

**If fees are not ready after bootstrap** (fallback):

1. http://localhost:8083/registrar/admin/term-fees?termId=1
2. **Zone 1 — Global import** or upload CSV from `registrar/setup/fees/`
3. Reload Settings readiness

**Finance policy** (admission, downpayment, installments): http://localhost:8083/registrar/admin/finance-policy — not Settings.

---

### Step 5 — Smoke test (2 minutes)

| Check | URL | Pass when |
|-------|-----|-----------|
| Registrar login | http://localhost:8083/registrar/login | admin / 1234 works |
| Enrollment login | http://localhost:8082/login | admin / 1234 works |
| Term fees | `/admin/term-fees?termId=1` | Programs load, no blockers |
| Finance policy | `/admin/finance-policy` | Admission, downpayment, installments editable |
| Classes | `/admin/classes` | BSCPE sections show times (not all TBA) |

---

## Default logins (after bootstrap)

| Username | Password | Use |
|----------|----------|-----|
| `admin` | `1234` | Admin — both apps |
| `cashier` | `1234` | Cashier — Enrollment |
| `prof.cruz` | `1234` | Faculty — grading via Registrar |

---

## What to do next

| Goal | Document | Section |
|------|----------|---------|
| **Demo / UAT sign-off** | `HUMAN_UAT_CHECKLIST.md` | Sessions 0–F |
| **Three lifecycle tracks + grading** | `THREE_TRACK_LIFECYCLE_DEMO_MANUAL.md` | Tracks 1–3 |
| **Full manual UAT / reference** | `MASTER_DEMO_UAT_MANUAL.md` | Part 7 (Sessions A–F) |
| **Live config demo (SQL + UI)** | same | Part 2M + Part 5M |
| **Full student lifecycle demo** | same | Part 8 (Y1→Y4) |
| **Balance / term close tests** | same | Part 9 |
| **Transferee / program shift** | same | Part 10 |
| **Automated preflight (optional)** | same | Part 6 — requires Python |

---

## Key files (quick reference)

| File | Purpose |
|------|---------|
| **`START_HERE_NEW_PC_HANDOFF.md`** | This document — new PC entry point |
| **`HUMAN_UAT_CHECKLIST.md`** | **Readable UAT / demo sign-off** (start here for testing) |
| **`THREE_TRACK_LIFECYCLE_DEMO_MANUAL.md`** | Y1→Y4 + transferee + shift + manual grades |
| **`HANDOFF_UPDATES_20260609.md`** | Latest fixes |
| **`MASTER_DEMO_UAT_MANUAL.md`** | Full reference manual |
| **`registrar/setup/AGENT_FRESH_SETUP.md`** | **Agents:** prereqs + bootstrap + smoke |
| **`registrar/setup/BOOTSTRAP_SEED_MANIFEST.md`** | Everything bootstrap seeds |
| **`registrar/setup/CHECK_PREREQUISITES.cmd`** | Machine gate before bootstrap |
| **`registrar/setup/RUN_FRESH_SETUP.cmd`** | One-shot DB bootstrap |
| `registrar/setup/fees/` | Program fee CSV templates |

## Troubleshooting (new PC)

| Problem | Fix |
|---------|-----|
| `mysql` not recognized | Add MariaDB/MySQL `bin` to PATH |
| Bootstrap fails on step 1 | MariaDB service not running |
| `Connection refused` on 8082/8083 | Start both apps; check ports not in use |
| Readiness not green | Import term-2 fees (Step 4 above) |
| `program_fee_settings` doesn't exist | Run `registrar/docs/business_logic/schema_migration_001.sql` in Workbench (or re-run bootstrap after fee seed step) |
| `enlistment_status` unknown column | Run `enrollment3/src/main/resources/sql/01_enlistment_status_schema.sql`, then **restart Enrollment** |
| Sections all **TBA** | Re-run step 7 in Workbench: `registrar/db/seed_all_class_schedules.sql` |
| Enrollment can't reach Registrar | Confirm `registrar.portal-base-url=http://localhost:8083/registrar` in enrollment `application.properties` |
| Port in use | `netstat -ano | findstr :8083` and `:8082` |

---

## Out of scope (do not block demo for these)

- TOR PDF upload / OCR
- Course equivalency table
- Scheduling automation / room conflicts
- Six retired programs: BSBA, BSCE, BSCS, BSECE, BSED, BSMATH
- Production fee rates (seeds use demo amounts)

---

## Handoff checklist — new PC ready when

- [ ] JDK, MariaDB, Maven, Workbench installed
- [ ] `registrar\setup\RUN_FRESH_SETUP.cmd` completed without errors
- [ ] Registrar + Enrollment both start on 8083 / 8082
- [ ] Settings readiness **Ready** for `1120242025`
- [ ] Smoke test (Step 5) passed
- [ ] Optional automated gate: `python -m pip install pymysql` then `python _runtime_logs/run_full_preflight.py --quick` → **7/7 PASS**

Then proceed to **`HUMAN_UAT_CHECKLIST.md`** for demo sign-off (or **`MASTER_DEMO_UAT_MANUAL.md`** Part 7 for full reference).

---

## Developer / agent context (optional)

For implementation history and batch cleanup notes (not needed for new PC demo):

- `MASTER_HANDOFF.md` — original stabilization handoff
- `CURRENT_STATE_MAP.md` — feature map
- `CROSS_APP_BRIDGE_20260608.md` — merged into master manual Part 11

**For new PC demo and UAT:** this file + `HANDOFF_UPDATES_20260609.md` + `MASTER_DEMO_UAT_MANUAL.md`.
