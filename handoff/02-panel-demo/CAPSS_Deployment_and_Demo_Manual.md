# CAPSS â€” Full Deployment & End-to-End Demo Manual
### EAC Computerized Academic Processing and Support System
**Version:** Jun 2026 (rev. 1 Jun 2026 PM) | Tested on: MySQL 8.0+ / MariaDB 10.4+, Spring Boot 3–4, JDK 17/21/25, Tomcat 10.1

---

## CHANGELOG

### Rev. 1 Jun 2026 (PM) — New PC handoff + forward-net docs
- **`../01-new-pc/NEW_PC_SETUP.md`** — copy folders, SQL order, build WARs on another machine (start here on new PC).
- **`../03-agent-dev/AGENT_HANDOVER_JUN2026.md`** — full agent/dev status, completed fixes, next sprint (`student_term_closes`).
- **Docs aligned:** `SQL_README.md`, `demo_full_lifecycle.sql` header, `../05-demo-guides/FRESH_FINANCE_DEMO.md`, `../05-demo-guides/FINANCE_FIX_STEPS.md` — forward **net** in totals (not gross).
- **Setup checklist fixed:** bootstrap + align + fees required before demo seed (not just `db/fix` + Maria script).

### Rev. 1 Jun 2026 — Finance demo pack + billing QA personas
- **Fresh finance retest:** `00_finance_demo_reset.sql` → `10_seed_finance_demo_personas.sql` → `11_finance_scenario_checks.sql` (see `../05-demo-guides/FRESH_FINANCE_DEMO.md`).
- **Personas:** `2026-0028` Student Manager Add, `2026-0027` forward payment math, `2026-0026` term transition forward debt.
- **Billing fixes documented:** term-close strict SL payments, forward **net** in total due, enlist block = forward debt ≥ PHP 100, Student Manager flash redirect (ASCII errors — Tomcat strips `₱` in Location header).
- **Rebuild** both WARs before finance QA.

### Rev. 30 May 2026 — Lifecycle grading inputs in demo manual
- **Demo manual:** Each lifecycle phase now lists exact **Prelim / Midterm / Final / Semestral** grade inputs per subject (matches `db/demo_scripts/*_demo_grades_*.sql`).
- **BSN lifecycle:** Documented reusable `02_demo_bsn_grades_current_term.sql` scoring pattern and per-term checklist.
- **RLE fees:** Enrollment calculates RLE as `units × hours_per_unit × hourly_rate` (admin label: **RLE rate per hour** on `/admin/term-fees`).
- **Elon Musk `2026-0002`:** Full 8-term BSIT grade seeds (`01`–`08` with `_2026-0002` suffix) — see `../05-demo-guides/README_DEMO_SQL.md`.
- **Constraint alignment:** Enrollment irregular/manual enlistment and Registrar Student Manager add/drop now enforce the same server-side checks: prerequisites, schedule conflict, unit load, and section capacity.
- **Historical enlistments:** Fresh schema no longer has a global `UNIQUE(student_id, course_id)` on `student_enlistments`; existing DBs can run `align_student_enlistments_history_key.sql` once.

### Rev. 28 May 2026 — Unified finance + fresh demo SQL
- **Critical:** Registrar `triggerTermTransition()` no longer wipes `student_ledger` payment rows or historical `student_enlistments` (root cause of empty previous-term ledger / Cashier ₱0 vs Registrar ₱57k mismatch).
- **Enrollment:** After finalize → `commitTermAssessment()`; walk-in pay → `reconcileLedgerWithPayments()`.
- **Single fee model:** Cashier/registrar read `program_general_fees` + `program_specific_fees`. `enrollment.fees.use-program-fee-rates=false` (skip `03_fee_term_versioning_schema.sql` on fresh demo).
- **Admin `/admin/term-fees`:** Edits the same core fee tables (term + program + year level + semester) in **both** registrar and enrollment — not `program_fee_rates`.
- **Historical ledger:** Previous terms remain read-only. Ledger can reconstruct old assessment/load from preserved enlistments, or from `grades` if older enlistments were already deleted.
- **Registrar add/drop + scholar cashier:** Legacy registrar-side paths are term-scoped and use the same core fee tables; no hardcoded tuition/misc/other assessment values.
- **Fresh demo order:** `db/fix` → `capss-demo-required/01_setup/01_fresh_demo_bootstrap.sql` → `capss-demo-required/01_setup/02_bsit_full_align_term_and_curriculum.sql` → `capss-demo-required/01_setup/03_seed_program_fees_full_lifecycle.sql` → `demo_elon_2026-0004_fresh.sql` or `demo_full_lifecycle.sql` (details: `../05-demo-guides/README_DEMO_SQL.md`).
- **Term codes:** Calendar `1120242025`; student `SL_1120242025` (see `../05-demo-guides/README_DEMO_SQL.md`, `../05-demo-guides/FINANCE_FIX_STEPS.md`).
- **Legacy repair only:** `fix_elon_2026-0004_finance_step_by_step.sql` — do not use on fresh DB; use fresh seed + rebuilt WARs instead.
- **Rebuild** both `registrar.war` and `enrollment.war` after pulling this revision.

### Rev. 27 May 2026 (PM) — Unified SQL (one script, no patch chain)
- **`db/fix`:** Single install script for Admission + Registrar + Enrollment3 (grading VIEW, fee tables, `programs.level`, VARCHAR `student_id` from create).
- **`../04-database/SQL_README.md`:** Full SQL inventory; deprecated hotfix/patch files listed.
- **Legacy DB only:** `db/eacdb_cross_system_schema.sql` (same as `registrar_enrollment_sync_patch.sql`) — not needed on fresh install.

### Rev. 27 May 2026 (AM) — Admission WAR + `programs.level`
- **Demo:** `00_demo_applicant_setup.sql` is applicant-only; `demo_full_lifecycle.sql` pre-creates `2026-1001` for enrollment-only demos.
- **Manual:** Phases 1–2 use Admission portal at `http://localhost:8080/admission`.

### Rev. 26 May 2026 (Evening) â€” Full student_id Key Audit & Bug Fixes
- **BUG FIX (Critical):** `FinancialService.syncLedgerAssessment()` was using `getUserId()` (INT) for all `student_ledger` and `student_enlistments` queries â€” now correctly uses `getId()` (student_number VARCHAR). This was the root cause of â‚±0.00 balance after block enroll.
- **BUG FIX (Critical):** `AcademicGradingService.triggerTermTransition()` â€” ledger read/write and `student_enlistments` DELETE all used `userId` instead of `studentNumber`. Forwarded balances were never persisted; accounting block never triggered after term change.
- **BUG FIX (Medium):** `FacultyController.viewSectionStudents()` â€” grade roster JOIN used `sys_users.user_id = student_enlistments.student_id` (INT vs VARCHAR); now uses `sys_users.username = student_enlistments.student_id`.
- **BUG FIX (Medium):** Scholarship fail check in term transition queried `grades` with `userId` (INT) â€” failing scholars incorrectly kept discounts. Now uses `studentNumber`.
- **BUG FIX (Medium):** `ScholarEnrollmentService.processWalkInPayment()` â€” walk-in PAYMENT ledger entry used `sysUserId` (INT) â€” now uses `studentNumber`.

### Rev. 26 May 2026 (Morning) â€” Registrar â†” Enrollment3 Integration Alignment
- Both sub-systems now share `eacdb` on port 3306. Registrar deployed as WAR alongside enrollment on port **8080** (Tomcat).
- `db/fix` (single consolidated file) replaces the multi-script pipeline.
- `registrar_enrollment_sync_patch.sql` (new) adds grading columns and VPAA tables not in `db/fix`.
- `AcademicGradingService`, `JaypeeIntegrationService`, `FinanceAdmissionService` rewritten to use canonical `grades`/`courses`/`curriculum_courses`/`faculty` tables.
- `courses.onlist` confirmed as `GENERATED ALWAYS AS (active_status) STORED` â€” set `active_status` to open/close a course.
- Full 4-year demo script added to this manual.

### Rev. 25 May 2026 â€” Student Table Migration & Cross-System ID Fix
- Dedicated `students` table added; `student_id` on transactional tables migrated INT â†’ VARCHAR.
- `syncLedgerAssessment` stale version removed; canonical `FinancialService` is sole calculator.
- Admission fee correctly imported as tuition credit in student ledger.
- Enrollment search dropdown added; error banner for no-result searches.

---

## SECTION 1 — New PC? Start here

**Another machine:** open **`../01-new-pc/NEW_PC_SETUP.md`** — copy folders, SQL order, build WARs.

**Continuing dev / agent handoff:** read **`../03-agent-dev/AGENT_HANDOVER_JUN2026.md`**.

Then follow **Section 3** (database) and **Section 4** (deploy) below.

---

## SECTION 2 — Prerequisites

Install in order on the demo PC.

### 1.1 JDK 17 or 21
- Download: https://adoptium.net (Temurin JDK 17 or 21)
- During install: check "Set JAVA_HOME" and "Add to PATH"
- Verify: `java -version` â†’ `openjdk version "17.x.x"` or `"21.x.x"`

### 1.2 MySQL 8.0 (or MariaDB 10.4+)
- Download: https://dev.mysql.com/downloads/installer/
- Root password: **leave blank** (matches default `application.properties`)
- Port: **3306** (default)
- Verify: open MySQL Workbench â†’ connect `localhost:3306` as `root` with no password

### 1.3 MySQL Workbench
- Download: https://dev.mysql.com/downloads/workbench/

### 1.4 Maven (for building from source â€” skip if using pre-built WARs)
- Download: https://maven.apache.org/download.cgi
- Extract and add `bin/` to PATH

---

## SECTION 2b â€” Files Needed

```
USB / delivery folder
├── registrar/                         ← source + db/fix + demo_scripts [REQUIRED]
├── enrollment3/                       ← enrollment source + mvnw.cmd [REQUIRED to build]
├── admission source/                  ← builds admission.war
├── registrar/handoff/                 ← all docs (this manual)
│   ├── 01-new-pc/
│   ├── 02-panel-demo/
│   ├── 03-agent-dev/
│   ├── 04-database/
│   └── 05-demo-guides/
├── db/fix                             ← inside registrar/ [REQUIRED once per PC]
├── db/demo_scripts/                   ← bootstrap, fees, demo seeds, grades
├── admission.war                      ← or build from source
├── registrar.war
└── enrollment.war
```

> Rename before copying:
> `registrar-0.0.1-SNAPSHOT.war` â†’ `registrar.war`
> `enrollment3-0.0.1-SNAPSHOT.war` â†’ `enrollment.war`
> `admission-0.0.1-SNAPSHOT.war` â†’ `admission.war`

---

## SECTION 3 â€” Database Setup

Open **MySQL Workbench** â†’ connect to `localhost:3306` as `root`.

For each script: **File â†’ Open SQL Script** â†’ select file â†’ press âš¡ **Execute All**.

---

### âš¡ SQL Execution Order â€” Quick Reference

Run these in order. Do not skip steps.

| # | Script | When to Run | What It Does |
|---|--------|-------------|--------------|
| 1 | `db/fix` | **Fresh setup only** (once) | Full unified schema + seed + admission/enrollment/registrar extensions (see `../04-database/SQL_README.md`) |
| 2 | `db/capss-demo-required/01_setup/01_fresh_demo_bootstrap.sql` | **After `db/fix`** | Calendar `academic_terms` + default open term |
| 3 | `db/capss-demo-required/01_setup/02_bsit_full_align_term_and_curriculum.sql` | **After step 2** | SET BSIT 48 courses + sections on every calendar term |
| 3b | `db/demo_scripts/01_seed_bsit_class_sections_demo.sql` | *(optional)* | Same sections as step 3 if you split scripts |
| 4 | `db/capss-demo-required/01_setup/03_seed_program_fees_full_lifecycle.sql` | **Before demo** | Core program fees (`program_general_fees`, `program_specific_fees`) — required |
| 4b | `/admin/term-fees` (UI) | **Optional** | Edit same core fee tables per term / program / YL / sem (registrar or enrollment) |
| *(opt)* | `03_fee_term_versioning_schema.sql` + `04_demo_fee_rates_two_terms.sql` | Legacy only | Alternate `program_fee_rates` model — skip unless `use-program-fee-rates=true` |
| 7 | `demo_full_lifecycle.sql` OR `demo_elon_2026-0004_fresh.sql` OR `00_demo_applicant_setup.sql` | **Before demo** | Maria / Elon / live applicant |
| 8 | **Build & deploy WARs** | **Before demo** | See `../01-new-pc/NEW_PC_SETUP.md` or `../05-demo-guides/FINANCE_FIX_STEPS.md` |
| 9 | `db/capss-demo-required/03_grades_maria/01_demo_grades_y1s1.sql` | **During demo** â€” after Y1S1 block enroll | 10 subjects â€” Year 1 Sem 1 grades |
| 10 | `db/capss-demo-required/03_grades_maria/02_demo_grades_y1s2.sql` | **During demo** â€” after Y1S2 block enroll | 8 subjects â€” Year 1 Sem 2 grades |
| 11 | `db/capss-demo-required/03_grades_maria/03_demo_grades_y2s1.sql` | **During demo** â€” after Y2S1 block enroll | 7 subjects â€” Year 2 Sem 1 grades |
| 12 | `db/capss-demo-required/03_grades_maria/04_demo_grades_y2s2.sql` | **During demo** â€” after Y2S2 block enroll | 6 subjects â€” Year 2 Sem 2 grades |
| 13 | `db/capss-demo-required/03_grades_maria/05_demo_grades_y3s1.sql` | **During demo** â€” after Y3S1 block enroll | 6 subjects â€” Year 3 Sem 1 grades |
| 14 | `db/capss-demo-required/03_grades_maria/06_demo_grades_y3s2.sql` | **During demo** â€” after Y3S2 block enroll | 5 subjects â€” Year 3 Sem 2 grades |
| 15 | `db/capss-demo-required/03_grades_maria/07_demo_grades_y4s1.sql` | **During demo** â€” after Y4S1 block enroll | 4 subjects â€” Year 4 Sem 1 grades |
| 16 | `db/capss-demo-required/03_grades_maria/08_demo_grades_y4s2.sql` | **During demo** â€” Y4S2 final semester | 2 subjects (Capstone 2 + OJT) + graduation check |

> Full list: `../05-demo-guides/README_DEMO_SQL.md`. Brent (`2026-0002`) and Elon (`2026-0004`) use the same scripts with `_2026-0002` / `_2026-0004` suffix.

> **Legacy DB only:** If you installed before May 27 2026 unified `db/fix`, run `db/eacdb_cross_system_schema.sql` once (same as old `registrar_enrollment_sync_patch.sql`).

**To repeat the demo from scratch** (without re-running `db/fix`):
```
Run: db/capss-demo-required/06_reset/00_demo_reset.sql   â† wipes Maria only, keeps all seed data
Then: demo_full_lifecycle.sql            â† re-seeds Maria
```

---

### Script 1: `db/fix` *(fresh setup — step 1 of 5)*

**What it does:** Full reset + seed + all cross-system schema in **one** Workbench execute:
- Drops and recreates all tables for Admission, Registrar, and Enrollment3
- `student_id` is **VARCHAR(100)** from create (ledger, enlistments, grades, waitlist, requests)
- `students` table, `programs.level`, `courses.onlist`, grading columns, `student_grades` VIEW
- Admission tables (`school_terms`, `users.email`/`enabled`, etc.)
- Enrollment fee tables (`enrollment_settings`, `program_general_fees`, `program_specific_fees`) + BSIT fee seed
- VPAA tables, grading period `system_settings`, staff logins (`admin`/`cashier`/`faculty` — password `1234`)
- Official SET BSIT curriculum/sections are seeded by `capss-demo-required/01_setup/02_bsit_full_align_term_and_curriculum.sql` after `db/fix`.

> âš  **This drops all existing data.** Only run on a fresh setup or intentional reset.

Expected result: No red errors. Final verification should show:
- `student_id` DATA_TYPE = `varchar` on transactional tables
- `student_grades` TABLE_TYPE = `VIEW`
- `programs.level` = `COLLEGE` for BSIT

See also: **`../04-database/SQL_README.md`** for the full file inventory.

---

### Legacy scripts *(do not run on fresh install)*

| Old script | Use only if |
|------------|-------------|
| `db/eacdb_cross_system_schema.sql` or `registrar_enrollment_sync_patch.sql` | You already ran an **older** `db/fix` before May 27 2026 PM unified version |
| `db/05_admission_eacdb_align.sql` | Same — merged into `db/fix`; use cross-system file for legacy DB |

---

### Script 2: Demo seeds *(pick one before the panel demo)*

| Script | Use when |
|--------|----------|
| `db/capss-demo-required/02_demo_seed_pick_one/00_demo_applicant_setup.sql` | Live flow: applicant `DEMO-SANTOS-001` + optional payment only — walk Phases 1–2 in the UI |
| `db/capss-demo-required/02_demo_seed_pick_one/demo_full_lifecycle.sql` | Skip to enrollment: pre-creates student `2026-1001`, ledger credit, enrollment window open |

---


## SECTION 4 â€” Deploy the Applications

### 4.1 Copy WAR files

> Use your Tomcat install path, e.g. `C:\apache-tomcat-10.1.54\`

```
<tomcat>\webapps\admission.war     ← after db/fix (fresh install needs no extra SQL)
<tomcat>\webapps\registrar.war     ← runs on port 8080 (same Tomcat as enrollment)
<tomcat>\webapps\enrollment.war    ← runs on port 8080
```

Rename before copying:
- `admission-0.0.1-SNAPSHOT.war` â†’ `admission.war`
- `registrar-0.0.1-SNAPSHOT.war.original` â†’ `registrar.war`
- `enrollment.war.original` â†’ `enrollment.war`

### 5.2 Start Tomcat

```batch
<tomcat>\bin\startup.bat
```

Wait for:
```
INFO: Server startup in [XXXX] milliseconds
```

### 5.3 Verify all three apps

| System      | URL                               | Expected                         |
|-------------|-----------------------------------|----------------------------------|
| Admission   | http://localhost:8080/admission   | EAC Admissions home / Apply page |
| Enrollment3 | http://localhost:8080/enrollment  | EAC Student Portal login page    |
| Registrar   | http://localhost:8080/registrar   | IUIMS Registrar login page       |

> All three WARs read the **same `eacdb` database** on port 3306 and run on Tomcat port **8080**. If `admission.war` fails with `Unknown column 'p1_0.level'`, run `db/eacdb_cross_system_schema.sql` (legacy DB) or re-run `db/fix` (fresh reset).

---

## SECTION 5 â€” Login Credentials

### Admission System (`http://localhost:8080/admission`)

| Role   | Username    | Password   | Access                         |
|--------|-------------|------------|--------------------------------|
| Admin  | admin-adms  | adminadms  | Applicant review, qualify, terms |
| Encoder| encoder-adms| encoderadms| Document encoding (if configured) |

> Created on first startup by `DataInitializer` when `app.bootstrap-admin.*` is set in `application.properties`. Login URL: `/admin/login`.

### Registrar System (`http://localhost:8080/registrar`)

| Role      | Username | Password | Access              |
|-----------|----------|----------|---------------------|
| Admin     | admin    | 1234     | Full access         |
| Faculty   | prof     | 1234     | Grade entry only    |

### Enrollment3 System (`http://localhost:8080/enrollment`)

| Role    | Username | Password | Access              |
|---------|----------|----------|---------------------|
| Admin   | admin    | 1234     | Full admin          |
| Cashier | cashier  | 1234     | Payment processing  |
| Faculty | faculty  | 1234     | Grade view          |

### Student Accounts (created during demo)
- **Username:** student number (e.g., `2026-0001`)
- **Password:** `1234`

---

## SECTION 6 â€” Full Lifecycle Demo: Application â†’ 4th Year Graduation

This section walks through the **complete academic journey** of one student from online application to their final semester in Year 4. Run `db/capss-demo-required/02_demo_seed_pick_one/00_demo_applicant_setup.sql` first to pre-load the applicant data.

---

### DEMO STUDENT: Maria Santos â€” BSIT

| Field | Value |
|-------|-------|
| Reference # | DEMO-SANTOS-001 |
| Name | Maria Santos |
| Program | BSIT |
| Email | maria.santos@demo.eac.edu.ph |

---

### PHASE 1 â€” Online Application

**Portal:** http://localhost:8080/admission (no login needed)

**Steps:**
1. Open **Admissions** home â†’ start a new application (College track)
2. Fill the application form:
   - First Name: `Maria`
   - Last Name: `Santos`
   - Email: `maria.santos@demo.eac.edu.ph`
   - Mobile: `09171234567`
   - Program Choice 1: `BSIT`
   - Sex: Female | Civil Status: Single
   - Fill other required fields (address, guardian, school history)
3. Upload dummy files for Form 138, Good Moral, PSA Birth Certificate, ID Picture
4. Click **Submit Application**

**Expected result:**
- Reference number generated: `EAC-XXXXXXXX`
- Status = `SUBMITTED`

> **SHORTCUT:** After `00_demo_applicant_setup.sql`, applicant `DEMO-SANTOS-001` is already `QUALIFIED FOR ENROLLMENT` with payment recorded. Skip to Phase 2 Step 2 (registrar) or Step 3 (enrollment cashier).

---

### PHASE 2 â€” Admission Processing

#### Step 1 â€” Document Review (Admission Admin)
**URL:** http://localhost:8080/admission/admin/login â†’ `admin-adms` / `adminadms`

1. Go to **Admin Dashboard** (`/admin/dashboard`)
2. Find `DEMO-SANTOS-001` (Maria Santos)
3. Click **View** â†’ tick all document checkboxes (Form 138 âœ“, Good Moral âœ“, PSA âœ“, ID âœ“)
4. Change status to **"Qualified for Enrollment"**
5. Click **Save**

**Expected:** Status changes to `QUALIFIED FOR ENROLLMENT`

---

#### Step 2 â€” Admission Fee Payment (Enrollment3 Cashier)
**URL:** http://localhost:8080/enrollment â†’ login as `cashier / 1234`

1. Go to **Walk-in Payment**
2. Search: `DEMO-SANTOS-001`
3. Enter Amount: `1000` | Method: `Cash`
4. Click **Process Payment**

**Expected:** Payment recorded. Balance = â‚±0 (minimum met).

> **NOTE:** The â‚±1,000 admission fee is automatically reclassified as "Tuition Fee" credit in the student ledger when the account is created.

---

#### Step 3 - Legacy Registrar Student-ID Demo

> Legacy note: this old panel demo shows Registrar approving and generating a student ID. That is no longer the current canon. Regular admission and student-number issuance now belong to Admission/Cashier. Registrar should only validate irregular Dean / Faculty pre-registration handoffs.

For current demos, complete regular admission outside Registrar. For irregular/transferee applicants, use Registrar Dean / Faculty advising to finalize the pre-registration handoff, then return to Admission/Cashier for payment, enrollment, and student-number issuance.

### PHASE 3 â€” Year 1, Semester 1 Enrollment

#### Step 1 â€” Assign Section (Enrollment3 Cashier Terminal)
**URL:** http://localhost:8080/enrollment/admin/cashier â†’ login as `cashier / 1234`

1. Search for `2026-1001` (Maria Santos)
2. Select **REGULAR (BLOCK)** mode
3. The Section Assignment bar shows available sections: `BSIT-1-1-A`, `BSIT-1-1-B`
4. Click `BSIT-1-1-A`
5. The table loads all Year 1 Sem 1 BSIT subjects for that section
6. Green badge: âœ… *Assigned: BSIT-1-1-A*

**Subjects enrolled in Y1S1 (SET BSIT official â€” 10 courses):**

| Course Code | Title (short) | Units |
|-------------|---------------|-------|
| AUS0 11 | Understanding the Self | 3 |
| ARPH 11 | Readings in Philippine History | 3 |
| SMMW 11 | Mathematics in the Modern World | 3 |
| AHU1 11 | Art Appreciation | 3 |
| ASS1011 | Social Sciences and Philosophy | 3 |
| PE1 11 | PE 1 (PATHFit 1) | 2 |
| ANS1 11 | CWTS/LTS/ROTC 1 | 3 |
| AECO 11 | Emilian Culture | 1 |
| UCO1 11 | Intro to IT | 3 |
| UPR1 11 | Fundamentals of Problem Solving & Programming | 3 |

#### Step 2 â€” Block Enroll
1. Click **"ENLIST ENTIRE BLOCK (BSIT-1-1-A)"**

**Expected:**
- All **10** subjects listed with âœ… On List status
- Real schedules shown â€” no TBA
- Status: `ADMITTED` â†’ **`ENROLLED`**
- Outstanding balance shows tuition + misc fees (not â‚±0.00)

---

#### Step 3 â€” Student Verifies Schedule
**URL:** http://localhost:8080/enrollment â†’ login as `2026-1001 / 1234`

**Expected:**
- Dashboard shows 10 enrolled subjects with day/time
- Financial section shows outstanding balance

---

### PHASE 4 — Year 1, Semester 1: Grade Encoding

After Y1S1 block enlist, grade all 10 subjects before term transition. Use **either** the SQL script **or** Registrar faculty grade entry with the values below.

#### Option A — SQL (recommended for panel demo speed)

1. Open **MySQL Workbench**
2. Run the grades seed script for Year 1 Semester 1:
   ```sql
   source db/capss-demo-required/03_grades_maria/01_demo_grades_y1s1.sql
   ```
   For Elon Musk `2026-0002`, use `01_demo_grades_y1s1_2026-0002.sql` instead.

#### Option B — Faculty grade entry (live demo)

**URL:** http://localhost:8080/registrar → login as `prof / 1234` → **My Classes** → `BSIT-1-1-A`

Enter these values for each subject (Prelim / Midterm / Final — semestral computes automatically):

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

#### Verify grades

3. **URL:** http://localhost:8080/registrar → login as `admin / 1234`
4. Go to **Student Manager** → search `2026-1001` (or `2026-0002` for Elon)
5. Click the **Academic History** tab

**Expected:**
- Year 1 Semester 1 subjects listed with Prelim, Midterm, Final, and computed Semestral grades.
- Status shows **Passed** for all 10 subjects.
- Script verify query shows `graded_subjects = 10`.

---

### PHASE 5 â€” Year 1, Semester 2 Enrollment

#### Step 1 â€” Term Transition (Registrar Admin)
**URL:** http://localhost:8080/registrar â†’ `admin / 1234`

1. Go to **System Settings â†’ Global Term Transition**
2. Set new term code: `2120252026` (2nd Semester 2025â€“2026)
3. Click **Transition All Students**

**Expected:**
- Maria's `semester`: 1 â†’ **2**; `year_level`: still **1**
- Status: `ENROLLED` â†’ `ADMITTED` (ready for re-enrollment)

---

#### Step 2 â€” Outstanding Balance Lock Demo
**URL:** http://localhost:8080/enrollment/admin/cashier

1. Search for `2026-1001`
2. The **Red Outstanding Balance Lock** appears â€” enrollment blocked

**Expected:** Lock shows exact balance owed from Y1S1.

---

#### Step 3 â€” Process Payment (Cashier)
1. Stay in cashier terminal
2. Find balance amount from lock screen (e.g., â‚±18,000)
3. Enter Amount: (full balance) | Method: Cash
4. Click **Process Payment**

**Expected:** Lock is removed. Student can now enlist.

---

#### Step 4 â€” Block Enroll Year 1 Sem 2
**Still in Cashier Terminal**

1. Click `BSIT-1-2-A` (Year 1, Semester 2, Section A)
2. Click **"ENLIST ENTIRE BLOCK"**

**Y1S2 Subjects (SET BSIT official â€” 8 courses):**

| Course Code | Title (short) | Units |
|-------------|---------------|-------|
| ACW0 12 | The Contemporary World | 3 |
| APC0 12 | Purposive Communication | 3 |
| AET0 12 | Ethics | 3 |
| SMST012 | Mathematics, Science & Technology | 3 |
| PE2 12 | PE 2 (PATHFit 2) | 2 |
| ANS2 12 | CWTS/LTS/ROTC 2 | 3 |
| UHC1 11 | Intro to Human Computer Interaction | 3 |
| UPR2 12 | Advanced Problem Solving & Programming | 3 |

**Expected:** **8** subjects enrolled, balance updated.

---

#### Step 5 — Grade Y1S2

Once Maria is enrolled in Y1S2, grade all 8 subjects before advancing to Year 2.

**SQL:**
```sql
source db/capss-demo-required/03_grades_maria/02_demo_grades_y1s2.sql
```
(Elon: `02_demo_grades_y1s2_2026-0002.sql`)

**Grade inputs — `BSIT-1-2-A`:**

| Course | Prelim | Midterm | Final | Semestral |
|--------|--------|---------|-------|-----------|
| AET0 12 | 87 | 89 | 91 | 1.50 |
| ANS2 12 | 85 | 86 | 88 | 1.75 |
| APC0 12 | 85 | 87 | 89 | 1.75 |
| PE2 12 | 90 | 91 | 92 | 1.25 |
| SMST012 | 84 | 86 | 88 | 1.75 |
| ACW0 12 | 86 | 88 | 90 | 1.75 |
| UHC1 11 | 82 | 84 | 86 | 2.00 |
| UPR2 12 | 88 | 90 | 92 | 1.50 |

Refresh **Academic History** — expect 8 **Passed** rows. Maria is ready to advance to Year 2.

---

### PHASE 6 â€” Year 2 Enrollment (Year Advancement)

#### Step 1 â€” Term Transition to Year 2
**Registrar Admin â†’ Global Term Transition**

1. Set term code: `1120262027` (1st Semester 2026â€“2027)
2. Click **Transition All Students**

**Expected:**
- Maria's `semester`: back to **1**; `year_level`: **1 â†’ 2**
- Logic: transitioning out of Sem 2 automatically advances year level

---

#### Step 2 â€” Settle Y1S2 Balance, Then Block Enroll Y2S1

Repeat: Payment â†’ BSIT-2-1-A section â†’ Block Enroll

**Y2S1 Subjects (SET BSIT â€” 7 courses):**

| Course Code | Title (short) | Units |
|-------------|---------------|-------|
| AHU2 21 | Arts and Humanities | 3 |
| ASS6 21 | Life, Works & Writing of Rizal | 3 |
| PE3 21 | PE 3 (PATHFit 3) | 2 |
| BEC0 12 | Accounting Principles | 3 |
| UPR3 21 | Object Oriented Programming | 3 |
| UDM0 21 | Discrete Mathematics | 3 |
| UIM0 12 | Intro to Information Management | 3 |

**Grade Y2S1** — run `03_demo_grades_y2s1.sql` (or `_2026-0002` suffix) **or** enter:

| Course | Prelim | Midterm | Final | Semestral |
|--------|--------|---------|-------|-----------|
| AHU2 21 | 88 | 89 | 91 | 1.50 |
| ASS6 21 | 86 | 88 | 90 | 1.75 |
| PE3 21 | 90 | 91 | 92 | 1.25 |
| BEC0 12 | 84 | 86 | 88 | 1.75 |
| UPR3 21 | 87 | 89 | 91 | 1.50 |
| UDM0 21 | 83 | 85 | 87 | 2.00 |
| UIM0 12 | 85 | 87 | 89 | 1.75 |

---

#### Step 3 — Y2S2 (repeat cycle)

Transition â†’ settle balance â†’ `BSIT-2-2-A` â†’ block enroll.

**Y2S2 Subjects (6 courses):**

| Course Code | Title (short) | Units |
|-------------|---------------|-------|
| STS0 22 | Science, Technology & Society | 3 |
| PE4 22 | PE 4 (PATHFit 4) | 2 |
| AEN4 22 | Business Correspondence | 3 |
| UNW122 | Networking 1 | 3 |
| UDS022 | Data Structures and Algorithms | 3 |
| UDB122 | Database Management System 1 | 3 |

**Grade Y2S2** — run `04_demo_grades_y2s2.sql` **or** enter:

| Course | Prelim | Midterm | Final | Semestral |
|--------|--------|---------|-------|-----------|
| STS0 22 | 86 | 88 | 90 | 1.75 |
| PE4 22 | 91 | 92 | 93 | 1.25 |
| AEN4 22 | 84 | 86 | 88 | 1.75 |
| UNW122 | 87 | 89 | 91 | 1.50 |
| UDS022 | 85 | 87 | 89 | 1.75 |
| UDB122 | 86 | 88 | 90 | 1.75 |

---

### PHASE 7 — Year 3 Enrollment

#### Y3S1 â€” Transition to 3rd Year

**Term code:** `1120272028`

**Y3S1 Subjects (6 courses):**

| Course Code | Title (short) | Units |
|-------------|---------------|-------|
| SMA3 21 | Statistics | 3 |
| USI1 31 | System Integration and Architecture 1 | 3 |
| UNW2 31 | Networking 2 | 3 |
| UEL2 31 | Tangible Technologies | 3 |
| UEL131 | Intangible Technologies | 3 |
| UDB231 | Advanced Database Systems | 3 |

---

#### Y3S2 Subjects (5 courses):

| Course Code | Title (short) | Units |
|-------------|---------------|-------|
| UADET 32 | Application Development and Emerging Technologies | 3 |
| UEDP0 32 | Event Driven Programming | 3 |
| UIAS1 32 | Information Assurance and Security 1 | 3 |
| UQM0 32 | Quantitative Methods | 3 |
| USPI 32 | Social and Professional Issues | 3 |

**Grade Y3S1** — run `05_demo_grades_y3s1.sql` **or** enter:

| Course | Prelim | Midterm | Final | Semestral |
|--------|--------|---------|-------|-----------|
| SMA3 21 | 85 | 87 | 89 | 1.75 |
| USI1 31 | 86 | 88 | 90 | 1.75 |
| UNW2 31 | 87 | 89 | 91 | 1.50 |
| UEL2 31 | 84 | 86 | 88 | 1.75 |
| UEL131 | 88 | 90 | 92 | 1.50 |
| UDB231 | 86 | 88 | 90 | 1.75 |

---

#### Y3S2 — block enroll, then grade

**Grade Y3S2** — run `06_demo_grades_y3s2.sql` **or** enter:

| Course | Prelim | Midterm | Final | Semestral |
|--------|--------|---------|-------|-----------|
| UADET 32 | 88 | 90 | 92 | 1.50 |
| UEDP0 32 | 86 | 88 | 90 | 1.75 |
| UIAS1 32 | 87 | 89 | 91 | 1.50 |
| UQM0 32 | 84 | 86 | 88 | 1.75 |
| USPI 32 | 85 | 87 | 89 | 1.75 |

---

### PHASE 8 â€” Year 4 (Graduating Student)

#### Step 1 â€” Transition to 4th Year

**Term code:** `1120282029`

At Year 4, the system automatically recognizes Maria as a **graduating student** (via `isGraduating()` which checks `MAX(curriculum_courses.year_level)` for BSIT). The max-unit allowance increases from 24 to **30 units**.

---

#### Step 2 â€” Y4S1 Enrollment

**Y4S1 Subjects (4 courses):**

| Course Code | Title (short) | Units |
|-------------|---------------|-------|
| UCP1 41 | Capstone Project 1 | 3 |
| UIAS2 41 | Information Assurance and Security 2 | 3 |
| USAM0 41 | Systems Administration and Maintenance | 3 |
| USI1 41 | System Integration and Architecture 2 | 3 |

> Graduating students may take up to **30 units** per term (vs 24 for non-graduating).

**Expected:** System allows up to 30 units. Block enrolls all Y4S1 subjects.

**Grade Y4S1** — run `07_demo_grades_y4s1.sql` **or** enter:

| Course | Prelim | Midterm | Final | Semestral |
|--------|--------|---------|-------|-----------|
| UCP1 41 | 88 | 90 | 92 | 1.50 |
| UIAS2 41 | 87 | 89 | 91 | 1.50 |
| USAM0 41 | 86 | 88 | 90 | 1.75 |
| USI1 41 | 88 | 90 | 92 | 1.50 |

---

#### Step 3 — Y4S2 Final Semester

**Term code:** `2120282029` (2nd Sem 2028â€“2029)

**Y4S2 Subjects (2 courses):**

| Course Code | Title (short) | Units |
|-------------|---------------|-------|
| UCP2 42 | Capstone Project 2 | 3 |
| UOJT 42 | On the Job Training | 9 |

**Grade Y4S2** — run `08_demo_grades_y4s2.sql` **or** enter:

| Course | Prelim | Midterm | Final | Semestral |
|--------|--------|---------|-------|-----------|
| UCP2 42 | 89 | 91 | 93 | 1.25 |
| UOJT 42 | 92 | 93 | 94 | 1.25 |

After all Y4S2 grades show **Passed**, Maria Santos has completed the BSIT program.

---

#### Step 4 â€” View Complete Academic History

**URL:** http://localhost:8080/registrar â†’ `admin / 1234` â†’ Student Manager â†’ search `2026-1001`

Click **Academic History** tab.

**Expected:**
- 4 years of grade records grouped by year level
- Prelim / Midterm / Final scores per subject
- Semestral grade computed and shown
- All subjects marked `Passed`
- Total units completed ≥ 143 (standard BSIT)

---

### PHASE 9 — BSN Full Lifecycle (optional)

Use this path to test Marian BSN curriculum, RLE hourly fees, and block sections across all terms.

#### Setup (once)

| Order | Script |
|-------|--------|
| 1 | `00_seed_bsn_curriculum_marian_official.sql` |
| 2 | `01_seed_bsn_class_sections_demo.sql` |

Create or approve a BSN demo student (e.g. `2026-0003`), then repeat per term:

1. Block enlist `BSN-{Y}-{S}-A` in Enrollment Cashier.
2. Pay / verify ledger.
3. **Grade the term** — set `@student_id` in `02_demo_bsn_grades_current_term.sql` and run it.
4. Confirm `graded_subjects = enlisted_subjects`.
5. Registrar term transition → next term.

**Grading pattern** (auto-generated per enlisted course, in course-code order):

| Component | Range / pattern |
|-----------|-----------------|
| Prelim | 84–90 |
| Midterm | 86–92 |
| Final | 88–94 |
| Semestral | 1.25, 1.50, 1.75, 2.00, or 2.25 (rotating) |

**Per-term expected counts:**

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

Full BSIT grade tables for all 8 terms: `../05-demo-guides/README_DEMO_SQL.md` → **Grading inputs by lifecycle stage**.

---

## SECTION 7 â€” Demo Test Data SQL

> âš ï¸ **Use `demo_full_lifecycle.sql` directly** â€” run it via MySQL Workbench **File â†’ Open SQL Script**, or via the PowerShell command in Section 13.
> The SQL below is shown for reference only and reflects the schema-verified version (corrected 27 May 2026).


```sql
-- ============================================================
-- demo_full_lifecycle.sql  (schema-corrected 27 May 2026)
-- Full demo student: Maria Reyes Santos (2026-1001 / pw: 1234)
-- Run AFTER: db/fix only
-- ============================================================
USE eacdb;
SET FOREIGN_KEY_CHECKS = 0;
SET SQL_SAFE_UPDATES   = 0;

-- â”€â”€ 1. Applicant record â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
INSERT IGNORE INTO applicants (
    reference_number, first_name, last_name, middle_name,
    email, mobile, sex, civil_status,
    program1, applicant_status, application_status,
    term_year, created_at, updated_at,
    form138_verified, good_moral_verified,
    psa_birth_cert_verified, id_picture_verified,
    semester, year_level, scholarship_type
) VALUES (
    'DEMO-SANTOS-001', 'Maria', 'Santos', 'Reyes',
    'maria.santos@demo.eac.edu.ph', '09171234567', 'Female', 'Single',
    'BSIT', 'QUALIFIED FOR ENROLLMENT', 'ADMISSION_PENDING',
    'SL_1120252026', NOW(), NOW(),
    1, 1, 1, 1,
    1, 1, 'NONE'
);

-- â”€â”€ 2. Admission payment (â‚±1,000 downpayment) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
INSERT IGNORE INTO payments (
    transaction_id, reference_number, amount, change_amount,
    payment_method, semester, year_level, term_year,
    remarks, status, payment_date
) VALUES (
    'PAY-DEMO-SANTOS-001', 'DEMO-SANTOS-001',
    1000.00, 0.00,
    'Cash (OTC)', 1, 1, 'SL_1120252026',
    'Admission Downpayment', 'COMPLETED', NOW()
);

-- â”€â”€ 3. sys_users account â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- NOTE: sys_users does NOT have enrollment_status_type (that is students-only).
INSERT IGNORE INTO sys_users (
    username, password, real_name, first_name, last_name, middle_name,
    role, program_code, year_level, semester, term_year,
    reference_number, student_type, admission_status,
    scholarship_type, discount_percentage,
    is_active, status, enrollment_blocked
) VALUES (
    '2026-1001',
    '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EhsLkT/Oh.reShMkwpfpJ2', -- pw: 1234
    'Maria Reyes Santos', 'Maria', 'Santos', 'Reyes',
    'Student', 'BSIT', 1, 1, 'SL_1120252026',
    'DEMO-SANTOS-001', 'Regular', 'ENROLLED',
    'NONE', 0.00,
    1, 'ACTIVE', 0
);

-- â”€â”€ 4. students table entry â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
INSERT IGNORE INTO students (
    student_number, user_id, reference_number,
    first_name, last_name, middle_name, real_name,
    email, mobile, program_code,
    year_level, semester, term_year,
    student_type, enrollment_status_type, admission_status,
    scholarship_type, scholarship_approved, scholarship_amount,
    discount_percentage, section_group,
    status, is_active, enrollment_blocked,
    password, role
) SELECT
    '2026-1001', u.user_id, 'DEMO-SANTOS-001',
    'Maria', 'Santos', 'Reyes', 'Maria Reyes Santos',
    'maria.santos@demo.eac.edu.ph', '09171234567', 'BSIT',
    1, 1, 'SL_1120252026',
    'Regular', 'REGULAR', 'ENROLLED',
    'NONE', 0, 0.00,
    0.00, 'A',
    'ACTIVE', 1, 0,
    '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EhsLkT/Oh.reShMkwpfpJ2', 'STUDENT'
FROM sys_users u WHERE u.username = '2026-1001';

-- â”€â”€ 5. Student ledger: initial payment â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
INSERT IGNORE INTO student_ledger (student_id, transaction_type, description, credit)
VALUES ('2026-1001', 'PAYMENT', 'Tuition Fee - Admission Downpayment', 1000.00);

-- â”€â”€ 6. Faculty assignment (safe â€” no INSERT, just assigns existing faculty) â”€â”€
SET @fac_id = (SELECT MIN(faculty_id) FROM faculty LIMIT 1);
UPDATE class_sections SET faculty_id = @fac_id
WHERE faculty_id IS NULL
  AND (section_code LIKE 'BSIT-1-%' OR section_code LIKE 'BSIT-2-%'
    OR section_code LIKE 'BSIT-3-%' OR section_code LIKE 'BSIT-4-%');

-- â”€â”€ 7. Open enrollment window â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
INSERT IGNORE INTO system_settings (setting_key, setting_value) VALUES ('enrollment_open', 'true');
UPDATE system_settings SET setting_value = 'true' WHERE setting_key = 'enrollment_open';

SET FOREIGN_KEY_CHECKS = 1;
SET SQL_SAFE_UPDATES   = 1;

-- Verify:
SELECT student_number, first_name, last_name, program_code, year_level, semester, admission_status
FROM students WHERE student_number = '2026-1001';

SELECT username, role, year_level, semester, admission_status
FROM sys_users WHERE username = '2026-1001';

SELECT student_id, transaction_type, description, credit
FROM student_ledger WHERE student_id = '2026-1001';
```

---

## SECTION 8 â€” Quick Demo Checklist (30-Minute Demo Script)

Use this checklist during the actual panel demo. Each phase is approximately 3â€“5 minutes.

```
SETUP (before panel arrives):
  [ ] db/fix — no red errors
  [ ] capss-demo-required/01_setup/01_fresh_demo_bootstrap.sql
  [ ] capss-demo-required/01_setup/02_bsit_full_align_term_and_curriculum.sql
  [ ] capss-demo-required/01_setup/03_seed_program_fees_full_lifecycle.sql
  [ ] demo_full_lifecycle.sql OR demo_elon_2026-0004_fresh.sql OR 00_demo_applicant_setup.sql
  [ ] Latest enrollment.war + registrar.war + admission.war deployed; Tomcat restarted
  [ ] All three apps on http://localhost:8080
  [ ] enrollment_open = true

PHASE 1 â€” Application (3 min)
  [ ] Open http://localhost:8080/admission in incognito/private window
  [ ] Show application form â€” fill in Maria Santos details
  [ ] Submit â†’ show reference number

PHASE 2 â€” Admission (5 min)
  [ ] Login as cashier â†’ Walk-in Payment â†’ DEMO-SANTOS-001 â†’ â‚±1,000
  [ ] Login as registrar admin â†’ Admission Acceptance â†’ approve â†’ note student# 2026-1001
  [ ] Show student ledger: Tuition Fee credit of â‚±1,000

PHASE 3 â€” Y1S1 Block Enrollment (5 min)
  [ ] Cashier terminal â†’ search 2026-1001
  [ ] REGULAR (BLOCK) â†’ click BSIT-1-1-A â†’ show subjects with real schedules
  [ ] ENLIST ENTIRE BLOCK â†’ show status = ENROLLED, balance > â‚±0

PHASE 4 â€” Student Portal (3 min)
  [ ] Incognito â†’ http://localhost:8080/enrollment â†’ login 2026-1001 / 1234
  [ ] Show enrolled subjects, schedule, and financial balance

PHASE 5 — Grade Encoding Y1S1 (3 min)
  [ ] Run `01_demo_grades_y1s1.sql` (or `_2026-0002` for Elon) in MySQL Workbench
  [ ] Or enter Prelim/Midterm/Final from Phase 4 grade table via Faculty portal
  [ ] Admin → Student Manager → Academic History → verify 10 Passed rows

PHASE 6 — Term Transition & Y1S2 (5 min)
  [ ] Admin → System Settings → Term Transition → 2120252026 (Sem 2)
  [ ] Show balance lock on cashier terminal → process payment → lock removed
  [ ] Block enroll Y1S2 (BSIT-1-2-A) → run `02_demo_grades_y1s2.sql` or enter Phase 5 grade table

PHASE 7 — Academic History (5 min)
  [ ] Admin â†’ Student Manager â†’ 2026-1001 â†’ Academic History tab
  [ ] Show pre-loaded 4-year grade history for Maria Santos
  [ ] Highlight: Year 1â†’4 progression, all Passed, semestral grades in point form
  [ ] Highlight: Year 4 graduating student â€” 30-unit limit active
```

---

## SECTION 9 â€” Constraint Demonstrations

Show these during the demo to prove system integrity:

| Action to Attempt | Where to Do It | Expected System Response |
|-------------------|----------------|--------------------------|
| Enlist same subject twice | Student self-service â†’ Available Subjects | âŒ Blocked: Currently Enrolled |
| Add subject with time overlap | Manual add via Registrar | âŒ Blocked: Time Conflict |
| Exceed 24 units (non-graduating) | Manual add in cashier terminal | âŒ Blocked: Exceeds Unit Limit (24) |
| Enlist without settling balance | Open cashier â†’ search student with balance | ðŸ”´ Red Balance Lock screen |
| Enlist subject needing unmet prereq | Manual add â†’ prereq-guarded course | âŒ Blocked: Needs [PREREQ CODE] |
| Graduating student at 28 units | Y4 student add extra subject | âœ… Allowed up to 30 units |

---

## SECTION 10 â€” URL Quick Reference

### Admission System (port 8080, path /admission)
```
Base: http://localhost:8080/admission

/                             Public home
/admissions                   Application landing
/admin/login                  Staff login
/admin/dashboard              Applicant pipeline (review, qualify, interview)
/admin/programs               Program list by level (read-only when shared DB)
```

### Registrar System (port 8080, path /registrar)
```
Base: http://localhost:8080/registrar

/login                        Login
/admin/dashboard              Main dashboard
/admin/admission-acceptance   Approve applicants â†’ generate student ID
/admin/student-manager        Manage students, add/drop subjects, view ledger
/admin/faculty-load           Faculty load tracker per department
/admin/classes                Grade entry (faculty portal)
/admin/ledger                 Financial ledger viewer
/admin/curriculum             Curriculum Management (view/seed programs)
/admin/class-scheduling       Open sections, assign faculty
```

### Enrollment3 System (port 8080)
```
Base: http://localhost:8080/enrollment

/login                        Login
/admin/dashboard              Admin overview
/admission/dashboard          Applicant pipeline (review â†’ qualify)
/admin/walkin-payment         Walk-in cashier payment
/admin/cashier                Enlistment terminal (section assign + block enroll)
/admin/enlistment             Admin-side manual subject add/drop
/admin/term-fees              Program fees per term (program_general_fees / program_specific_fees)
/admin/course-fees            Course-specific fee add-ons (lab/computer per subject, per term)
/student/dashboard            Student self-service (view schedule, add/drop, ledger)
```

### Per-term fee edit demo — Quick Steps

Proves fees can differ by academic term while cashier and registrar read the same core tables.

**Prereqs:** `capss-demo-required/01_setup/03_seed_program_fees_full_lifecycle.sql` (or fresh bootstrap + fee seed).

**UI (either app; same DB):**
- Registrar: http://localhost:8080/registrar/admin/term-fees
- Enrollment: http://localhost:8080/enrollment/admin/term-fees

**Steps (BSIT example):**
1. Load Term A, program `BSIT`, year level Y1, semester 2nd
2. Change `TUITION_PER_UNIT`, Save
3. Block-enlist a BSIT Y1 S2 student on Term A → note cashier assessment total
4. Open registrar Student Manager for same student/term → totals should match
5. Switch to Term B, set a different `TUITION_PER_UNIT`, Save → re-enlist on Term B → new rate applies

---

## SECTION 11 â€” Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| 404 on /registrar | Wrong path or Tomcat not started | Use http://localhost:**8080**/registrar |
| 404 on /admission | WAR missing or wrong name | File must be `admission.war` in webapps\ |
| `admission.war` fails: `Unknown column 'p1_0.level'` | `programs.level` missing | Re-run `db/fix` **or** run `db/eacdb_cross_system_schema.sql`, restart Tomcat |
| 404 on /enrollment | WAR named incorrectly | File must be `enrollment.war` in webapps\ |
| Red error: `Unknown column 'onlist'` | `db/fix` not run yet | Run `db/fix` in Workbench |
| Red error: `Table 'eacdb.students' doesn't exist` | `db/fix` not run | Run `db/fix` in Workbench |
| Red error: `Unknown column 'prelim' in grades` | Old `db/fix` without unified extensions | Re-run `db/fix` **or** run `db/eacdb_cross_system_schema.sql` |
| Balance shows â‚±0.00 after block enroll | Stale `enrollment.war` or wrong `student_id` in ledger | Rebuild/deploy latest enrollment WAR; verify `student_ledger.student_id` is VARCHAR student number |
| Cashier outstanding ≠ Registrar Student Manager | Dual fee tables, wiped payments, or stale WAR | Rebuild **both** WARs; use core fees only (`use-program-fee-rates=false`); run `audit_elon_2026-0004_finance_reconcile.sql` read-only; avoid `fix_elon_*.sql` on fresh DB |
| Tuition changed in UI but enlist total unchanged | Edited wrong YL/sem or wrong term scope | `/admin/term-fees`: match student's year level, semester, and active term; Save then re block-enlist |
| Block enroll adds 0 subjects | `program_code` not set, or `active_status=0` on courses | `SELECT active_status, onlist FROM courses LIMIT 5` â€” onlist should = 1 |
| Section buttons show but no subjects | Official BSIT curriculum/sections not seeded | Run `capss-demo-required/01_setup/02_bsit_full_align_term_and_curriculum.sql` |
| Block enlist shows wrong count (e.g. 40 units) | Stale `enrollment.war` or BSCS-clone curriculum | Rebuild enrollment3; run `capss-demo-required/01_setup/02_bsit_full_align_term_and_curriculum.sql` |
| Ledger term dropdown changes enrollment term | Old enrollment WAR | Deploy latest `enrollment.war` (ledger term is **view-only**) |
| Faculty names show blank in schedules | `faculty.first_name` / `last_name` null | `UPDATE faculty SET first_name=..., last_name=... WHERE faculty_id=?` |
| Grades not visible in academic history | `grades.student_id` still INT (legacy DB) | Re-run `db/fix` **or** run `db/eacdb_cross_system_schema.sql` |
| `student_grades` view missing | Old `db/fix` without unified extensions | Same as above |
| Previous-term official ledger is empty | Old transition deleted enlistments, or grades not seeded yet | Deploy latest WARs; run the matching grade script so ledger can reconstruct old term if enlistments were already deleted |
| Accounting block never appears after term change | Forwarded balance not written to ledger | Same — `AcademicGradingService.triggerTermTransition()` must preserve PAYMENT rows |
| Walk-in payment not reflected in balance | Stale registrar/enrollment WAR | Rebuild both; payments reconcile via `reconcileLedgerWithPayments()` |
| Payments show ₱0 paid in Registrar after term change | Old transition deleted ledger PAYMENT rows | Rev. 28 registrar WAR; re-seed student or run repair SQL only on legacy corrupted DB |
| Port 8080 already in use | Another process on 8080 | Kill the process: `netstat -ano | findstr 8080`, then `taskkill /PID <pid> /F` |
| Outstanding balance lock after fresh enroll (no prior balance) | Stale ledger rows from previous demo run | Run: `DELETE FROM student_ledger WHERE student_id='2026-1001' AND transaction_type NOT IN ('PAYMENT','INITIAL_PAYMENT')` |
| Login `admin/1234` fails | BCrypt hash issue from PowerShell `$` escape | Run: `UPDATE sys_users SET password='$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EhsLkT/Oh.reShMkwpfpJ2' WHERE username='admin'` |
| App crashes on startup | Wrong JDK | Must be JDK 17 or 21. Run: `java -version` |
| `demo_full_lifecycle.sql` fails with "Unknown column 'enrollment_status_type' in field list" | Old script had `enrollment_status_type` in `sys_users` INSERT â€” that column only exists on `students`, not `sys_users` | Use the corrected script (27 May 2026 version) â€” already fixed in the file |
| `demo_full_lifecycle.sql` fails with "Unknown column 'user_id' in field list" for faculty table | Old script tried to INSERT into `faculty` using `user_id` but `faculty` has `employee_number` (NOT NULL) | Use the corrected script â€” faculty section now uses a safe UPDATE instead of INSERT |
| Maria Santos (2026-1001) not found in system after running lifecycle script | Script failed mid-way (e.g. faculty INSERT error) â€” partial data was written | Run `00_demo_reset.sql` to wipe the partial data, then re-run the corrected `demo_full_lifecycle.sql` |


---

## SECTION 12 â€” Database Schema Reference (Rev. 26 May 2026)

### Key Tables

| Table | Primary Key | Purpose |
|-------|-------------|---------|
| `students` | `student_number VARCHAR(100)` | Canonical student profile |
| `sys_users` | `user_id INT` | Authentication (Spring Security); `username` = `student_number` |
| `student_ledger` | `ledger_id INT` | Financial transactions; `student_id` = `student_number` (VARCHAR) |
| `student_enlistments` | `enlistment_id INT` | Enrolled subjects; `student_id` = `student_number` (VARCHAR) |
| `grades` | `id BIGINT` | Academic grades; `student_id` = `student_number` (VARCHAR) |
| `student_grades` | VIEW | Aliases `grades` to legacy column names for registrar grading code |
| `courses` | `course_id INT` | Course catalog; `onlist` = GENERATED AS `active_status` |
| `curriculum_courses` | `curriculum_course_id INT` | Maps courses to program/year/semester |
| `class_sections` | `section_id INT` | One section per course per term (e.g., BSIT-1-1-A) |
| `class_schedules` | `schedule_id INT` | Time slots per section |

### Student ID Type After Migration

| Table | `student_id` type | References |
|-------|-------------------|-----------|
| `student_ledger` | `VARCHAR(100)` | `students.student_number` |
| `student_enlistments` | `VARCHAR(100)` | `students.student_number` |
| `grades` | `VARCHAR(100)` | `students.student_number` |
| `subject_requests` | `VARCHAR(100)` | `students.student_number` |
| `student_waitlist` | `VARCHAR(100)` | `students.student_number` |

### Script Execution Order (Fresh Setup)

```
1. db/fix                                    â€” only required script (schema + seed + all 3 systems)
2. db/capss-demo-required/02_demo_seed_pick_one/00_demo_applicant_setup.sql   OR   demo_full_lifecycle.sql   [demo only]
3. db/demo_scripts/01–08_demo_grades_*.sql   [during demo, per term]
```

Legacy DB (installed before unified `db/fix`): run `db/eacdb_cross_system_schema.sql` once instead of steps 2–3 in the old manual.

### Verification Queries

```sql
-- 1. Check student_id types (all should be varchar)
SELECT TABLE_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'eacdb'
  AND TABLE_NAME IN ('student_ledger','student_enlistments','grades','subject_requests')
  AND COLUMN_NAME = 'student_id'
ORDER BY TABLE_NAME;

-- 2. Check onlist is GENERATED
SELECT COLUMN_NAME, DATA_TYPE, GENERATION_EXPRESSION
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'eacdb' AND TABLE_NAME = 'courses' AND COLUMN_NAME = 'onlist';
-- Expected: tinyint | active_status

-- 3. Check grading columns exist
SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'eacdb' AND TABLE_NAME = 'grades'
  AND COLUMN_NAME IN ('prelim','midterm','final_grade','semestral_grade','section_id');
-- Expected: 5 rows

-- 4. Check student_grades VIEW exists
SELECT TABLE_NAME, TABLE_TYPE FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'eacdb' AND TABLE_NAME = 'student_grades';
-- Expected: VIEW

-- 5. Check demo student loaded
SELECT student_number, first_name, last_name, program_code, year_level, semester
FROM students WHERE student_number = '2026-1001';

-- 6. Check demo student's grade history
SELECT c.course_code, g.prelim, g.midterm, g.final_grade, g.semestral_grade, g.remarks
FROM grades g JOIN courses c ON g.course_id = c.course_id
WHERE g.student_id = '2026-1001'
ORDER BY g.date_recorded, c.course_code;
-- Expected: 16 rows (4 per semester Ã— 4 semesters)
```

---

## SECTION 13 â€” Demo Reset (Between Runs)

Run this in MySQL Workbench to wipe the demo student and repeat the demo from scratch **without re-running `db/fix`** (which would wipe all course/curriculum seed data).

```sql
-- ============================================================
-- DEMO RESET â€” removes Maria Santos only, keeps all seed data
-- Run in MySQL Workbench between demo runs
-- ============================================================
USE eacdb;
SET FOREIGN_KEY_CHECKS = 0;
SET SQL_SAFE_UPDATES   = 0;

-- Remove grades
DELETE FROM grades            WHERE student_id = '2026-1001';
-- Remove enlistments
DELETE FROM student_enlistments WHERE student_id = '2026-1001';
-- Remove ledger
DELETE FROM student_ledger    WHERE student_id = '2026-1001';
-- Remove student profile
DELETE FROM students          WHERE student_number = '2026-1001';
-- Remove auth account
DELETE FROM sys_users         WHERE username = '2026-1001';
-- Remove applicant record
DELETE FROM applicants        WHERE reference_number = 'DEMO-SANTOS-001';
-- Remove admission payment
DELETE FROM payments          WHERE reference_number = 'DEMO-SANTOS-001';
DELETE FROM applicant_payments WHERE applicant_id   = 'DEMO-SANTOS-001';

SET FOREIGN_KEY_CHECKS = 1;
SET SQL_SAFE_UPDATES   = 1;

-- Then re-run:
-- source db/capss-demo-required/02_demo_seed_pick_one/00_demo_applicant_setup.sql
-- (or demo_full_lifecycle.sql for the full pre-loaded version)
```

---

*Built with Spring Boot 3 | MySQL 8.0 | Apache Tomcat 10.1 | Thymeleaf*
*Curriculum data sourced from official EAC .docx curriculum documents.*
*Registrar: port 8080 | Enrollment3: port 8080 | Shared DB: eacdb @ port 3306*
*Last bug-fix revision: 26 May 2026 (evening) â€” all student_id key type mismatches resolved.*

