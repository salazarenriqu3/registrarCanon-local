# Registrar System — Storyboard Presentation

**Format:** Act → Scene → Visual → Narration → Actions → MySQL  
**Duration:** ~50 minutes (+ 10 min Q&A)  
**Presenter login:** `admin` / `1234`  
**URL:** http://localhost:8083/registrar  
**Checklist map:** Items 1.1–7.10 from evaluator requirements sheet

---

## How to use this document

1. Run **Act 0** SQL once before the audience arrives (or use `RUN_STORYBOARD_DEMO_PREP.cmd`).
2. Start Registrar + Enrollment apps.
3. Follow each scene in order — **Visual** is what the projector shows; **Narration** is what you say.
4. Copy-paste **MySQL** blocks directly into MySQL Workbench when a scene says "verify in database."
5. Mark checklist items on `REQUIREMENTS_EVALUATION_CHECKLIST.md` as you go.

**One-file SQL prep (recommended):**

```cmd
mysql -u root eacdb < registrar/db/demo_scripts/STORYBOARD_SQL_ALL_IN_ONE.sql
```

Or:

```cmd
registrar\db\demo_scripts\RUN_STORYBOARD_DEMO_PREP.cmd
```

---

# ACT 0 — Before the Curtain (Pre-show, 10 min)

*Audience not required. Run on demo laptop.*

---

### Scene 0.1 — Lights check: apps & term

| | |
|---|---|
| **Visual** | Terminal: `mvn spring-boot:run` logs; browser tab on login page |
| **Narration** | *(silent — prep only)* |
| **Actions** | Start Registrar (8083). Start Enrollment (8082) if cross-app demo needed. |

**MySQL — confirm active term:**

```sql
USE eacdb;

SELECT term_id, term_code, term_name, is_active
FROM academic_terms WHERE is_active = 1;

SELECT setting_key, setting_value
FROM system_settings
WHERE setting_key = 'CURRENT_ACADEMIC_TERM';
```

**Expected:** `1120242025`, term_id `1`.

---

### Scene 0.2 — Fresh database (new machine only)

| | |
|---|---|
| **Visual** | Command prompt running bootstrap |
| **Narration** | *(prep)* |
| **Actions** | Only on disposable DB — **destroys all data** |

```cmd
registrar\setup\RUN_FRESH_SETUP.cmd
```

**MySQL — after bootstrap, confirm fee readiness:**

```sql
USE eacdb;

SELECT COUNT(*) AS fee_rows_active_term
FROM program_fee_settings pfs
JOIN academic_terms t ON t.term_id = pfs.term_id AND t.is_active = 1;
```

---

### Scene 0.3 — Upgrade existing database (staging laptop)

| | |
|---|---|
| **Visual** | Migration runner output |
| **Narration** | *(prep)* |
| **Actions** | Non-destructive — use when DB already has production-like data |

```cmd
registrar\db\migrations\RUN_UPGRADE.cmd
```

**MySQL — confirm sprint tables:**

```sql
USE eacdb;

SHOW TABLES LIKE 'grading_schemes';
SHOW TABLES LIKE 'student_holds';
SHOW TABLES LIKE 'student_program_shift_requests';
```

---

### Scene 0.4 — Load storyboard demo data

| | |
|---|---|
| **Visual** | MySQL Workbench running STORYBOARD_SQL_ALL_IN_ONE |
| **Narration** | *(prep)* |

**MySQL — paste entire prep script OR run CLI:**

```sql
-- Quick path: run the full file in Workbench
-- File → Open → registrar/db/demo_scripts/STORYBOARD_SQL_ALL_IN_ONE.sql → Execute

-- Or paste this summary block:
USE eacdb;

UPDATE system_settings SET setting_value = '2026-01-01' WHERE setting_key = 'ENROLLMENT_OPEN_DATE';
UPDATE system_settings SET setting_value = '2026-12-31' WHERE setting_key = 'ENROLLMENT_CLOSE_DATE';
UPDATE system_settings SET setting_value = '2026-08-15' WHERE setting_key = 'ADD_DROP_CLOSE_DATE';

INSERT INTO students (student_number, reference_number, real_name, program_code,
  year_level, semester, enrollment_status_type, student_type)
SELECT 'SPRINT-DEMO-2026-001', 'SPRINT-DEMO-REF-001', 'Sprint Demo Student', 'BSCPE',
  1, 1, 'ENROLLED', 'REGULAR'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM students WHERE student_number = 'SPRINT-DEMO-2026-001');

DELETE FROM student_holds WHERE student_number = 'SPRINT-DEMO-2026-001' AND office = 'OSA';
INSERT INTO student_holds (student_number, office, reason, active, created_by)
VALUES ('SPRINT-DEMO-2026-001', 'OSA', 'Demo hold — unreturned student ID', 1, 'storyboard');
```

**Optional — withdrawal demo student (Act 5):**

```cmd
mysql -u root eacdb < registrar/db/demo_scripts/16_withdrawal_uat_seed.sql
```

---

### Scene 0.5 — Build gate

```cmd
cd registrar
mvn -q test -Dtest=!ModulithTests
mvn -q -DskipTests package
```

---

# ACT 1 — Opening: Academic Foundation (8 min)

*Checklist: 1.3, 1.5, 1.6, 1.7, 4.1, 4.2*

---

### Scene 1.1 — Title card

| | |
|---|---|
| **Visual** | Login → Dashboard |
| **Narration** | "Good [morning/afternoon]. This is the IUIMS Registrar module — programs, curricula, scheduling, records, and academic governance in one place." |
| **Actions** | Login `admin` / `1234` |

---

### Scene 1.2 — Program Builder

| | |
|---|---|
| **Visual** | `/admin/programs` |
| **Narration** | "Programs are created here with duration and department. Once saved, the program code is locked — preventing accidental renames that would break historical records." |
| **Actions** | Show list → Create `DEMO-PRG` (4 years) → Save → Edit → show code readonly → Cancel delete on in-use program |
| **Checklist** | 1.3 Pass, 1.7 Pass |

**MySQL — verify program row:**

```sql
USE eacdb;

SELECT program_code, program_name, duration_years, active_status
FROM programs
WHERE program_code = 'DEMO-PRG';
```

---

### Scene 1.3 — Course Catalog & code lock

| | |
|---|---|
| **Visual** | `/admin/course-catalog` |
| **Narration** | "Courses are reusable catalog entries. LEC and LAB units are configured here. The course code cannot be changed after first save." |
| **Actions** | Edit any course → show readonly code → set **Course type** dropdown |
| **Checklist** | 1.6 Pass, 4.5 Partial |

**MySQL — course types:**

```sql
USE eacdb;

SELECT course_code, course_title, lec_units, lab_units, course_type
FROM courses
WHERE course_type <> 'REGULAR'
LIMIT 10;
```

---

# ACT 2 — Scheduling & Slot Control (10 min)

*Checklist: 4.4, 4.8, 4.9, 4.10, 7.9*

---

### Scene 2.1 — Class Scheduling overview

| | |
|---|---|
| **Visual** | `/admin/class-scheduling` — term selector `1120242025` |
| **Narration** | "Scheduling is term-aware. Block sections group a cohort; irregular students use open IRREG sections." |
| **Actions** | Show term filter → Load Block Details → expand one block |
| **Checklist** | 4.1 Pass, 4.2 Pass |

---

### Scene 2.2 — Remove subject from block

| | |
|---|---|
| **Visual** | Block panel → trash icon on a course with zero enlistments |
| **Narration** | "Registrars can remove a subject from a block template when no students are enlisted yet." |
| **Actions** | Click remove → confirm |
| **Checklist** | 4.4 Pass |

**MySQL — block sections for active term:**

```sql
USE eacdb;

SELECT cs.section_id, cs.section_code, c.course_code, cs.section_status,
  (SELECT COUNT(*) FROM student_enlistments se WHERE se.section_id = cs.section_id) AS enlisted
FROM class_sections cs
JOIN courses c ON c.course_id = cs.course_id
JOIN academic_terms t ON t.term_id = cs.term_id AND t.is_active = 1
WHERE cs.block_id IS NOT NULL
LIMIT 10;
```

---

### Scene 2.3 — Slot Monitoring dashboard

| | |
|---|---|
| **Visual** | `/admin/slot-monitoring` |
| **Narration** | "This is the unified slot board: enrolled versus pre-registered counts, capacity edits, close, dissolve, and bulk close." |
| **Actions** | Filter → edit capacity → Close one section → Bulk close with checkbox |
| **Checklist** | 4.8 Pass, 4.9 Pass |

**MySQL — slot counts mirror:**

```sql
USE eacdb;

SELECT cs.section_code, c.course_code, cs.max_capacity, cs.section_status,
  (SELECT COUNT(*) FROM student_enlistments se
   WHERE se.section_id = cs.section_id AND se.enlistment_status = 'COMMITTED') AS enrolled,
  (SELECT COUNT(*) FROM student_enlistments se
   WHERE se.section_id = cs.section_id AND se.enlistment_status = 'STAGED') AS prereg
FROM class_sections cs
JOIN courses c ON c.course_id = cs.course_id
JOIN academic_terms t ON t.term_id = cs.term_id AND t.is_active = 1
LIMIT 15;
```

---

### Scene 2.4 — Faculty loading permission

| | |
|---|---|
| **Visual** | Class Scheduling → faculty dropdown (as ADMIN) |
| **Narration** | "Faculty assignment is restricted to Dean and Admin roles — the Registrar alone cannot assign loading." |
| **Checklist** | 4.10 Partial, 7.9 Pass |

---

# ACT 3 — Student Records & Registration Forms (10 min)

*Checklist: 3.1, 3.2, 3.5, 3.6, 3.8*

---

### Scene 3.1 — Student Profile

| | |
|---|---|
| **Visual** | `/admin/student-manager?username=SPRINT-DEMO-2026-001` |
| **Narration** | "Student Profile centralizes academic identity, curriculum assignment, alerts, and document history." |
| **Checklist** | 3.7 Pass |

---

### Scene 3.2 — Registration Form naming

| | |
|---|---|
| **Visual** | Print Registration Form (student with STAGED only vs COMMITTED) |
| **Narration** | "Before payment the document reads Pre-Registration Form. After commitment it becomes Registration Form — not Certificate of Registration." |
| **Checklist** | 3.1 Pass |

**MySQL — enlistment status drives title:**

```sql
USE eacdb;

SELECT se.student_id, se.enlistment_status, c.course_code, cs.section_code
FROM student_enlistments se
JOIN class_sections cs ON cs.section_id = se.section_id
JOIN courses c ON c.course_id = se.course_id
JOIN academic_terms t ON t.term_id = cs.term_id AND t.is_active = 1
WHERE se.student_id IN ('SPRINT-DEMO-2026-001', '2026-1001')
LIMIT 20;
```

---

### Scene 3.3 — Payment gate on print

| | |
|---|---|
| **Visual** | Attempt print on unpaid student → redirect/block message |
| **Narration** | "Registration Forms print only after the downpayment threshold is met — protecting academic records from premature release." |
| **Checklist** | 3.2 Pass |

**MySQL — downpayment settings:**

```sql
USE eacdb;

SELECT setting_key, setting_value
FROM system_settings
WHERE setting_key IN ('DOWNPAYMENT_THRESHOLD', 'DOWNPAYMENT_PERCENT', 'ACCOUNTING_BLOCK_THRESHOLD');
```

---

### Scene 3.4 — TOR with editable fields

| | |
|---|---|
| **Visual** | `/admin/print-tor` → form → print preview |
| **Narration** | "TOR generation captures registrar-entered remarks, special order, graduation status, and purpose before printing." |
| **Checklist** | 3.6 Pass |

---

### Scene 3.5 — COG & audit trail

| | |
|---|---|
| **Visual** | Print COG → Student Profile document trail |
| **Narration** | "Every print is logged with timestamp and purpose for lifecycle tracking." |
| **Checklist** | 3.5 Pass, 3.8 Pass |

**MySQL — registration form events:**

```sql
USE eacdb;

SELECT event_type, student_number, event_summary, created_at, created_by
FROM reg_form_events
ORDER BY created_at DESC
LIMIT 10;
```

---

# ACT 4 — Governance: Withdrawal & Program Shift (12 min)

*Checklist: 2.11, 5.1–5.5, 2.2*

---

### Scene 4.1 — Withdrawal request (Student Profile)

| | |
|---|---|
| **Visual** | Student Manager → enrolled subject → Withdraw + reason dropdown |
| **Narration** | "We use the term WITHDRAW — not drop. The student or registrar initiates; the subject stays until both Dean and Registrar approve." |
| **Actions** | Use `WDRW-UAT-2026-001` if withdrawal seed loaded |
| **Checklist** | 5.1 Pass, 5.2 Pass, 5.4 Pass |

**MySQL — preload withdrawal student (if not seeded):**

```cmd
mysql -u root eacdb < registrar/db/demo_scripts/16_withdrawal_uat_seed.sql
```

**MySQL — verify enlisted subject:**

```sql
USE eacdb;

SELECT se.student_id, c.course_code, se.enlistment_status, wr.status AS withdrawal_status
FROM student_enlistments se
JOIN courses c ON c.course_id = se.course_id
LEFT JOIN student_withdrawal_requests wr
  ON wr.student_number = se.student_id AND wr.section_id = se.section_id
  AND wr.status NOT IN ('APPROVED','REJECTED')
WHERE se.student_id = 'WDRW-UAT-2026-001';
```

---

### Scene 4.2 — Dean approval

| | |
|---|---|
| **Visual** | `/faculty/withdrawals` → Approve |
| **Narration** | "Dean review is the first gate — post-payment academic changes require academic approval." |
| **Checklist** | 2.2 Pass |

---

### Scene 4.3 — Registrar execution

| | |
|---|---|
| **Visual** | `/admin/withdrawals` → Approve → subject removed |
| **Narration** | "Registrar final approval removes the enlistment and applies the prorated charge tier: 25%, 50%, or 100% based on timing." |
| **Checklist** | 5.2 Pass, 2.11 Pass |

**MySQL — penalty setting & request outcome:**

```sql
USE eacdb;

SELECT setting_key, setting_value
FROM enrollment_settings
WHERE setting_key = 'drop_penalty_first_week_percent';

SELECT request_id, student_number, timing_bucket, charge_percent, estimated_charge, status
FROM student_withdrawal_requests
WHERE student_number = 'WDRW-UAT-2026-001'
ORDER BY request_id DESC LIMIT 3;
```

---

### Scene 4.4 — Midterm deadline

| | |
|---|---|
| **Visual** | Settings or Finance Policy → midterm date context |
| **Narration** | "After the configured midterm exam date, new withdrawal requests are blocked." |
| **Checklist** | 5.5 Pass |

**MySQL — midterm date:**

```sql
USE eacdb;

SELECT t.term_code, p.midterm_exam_date
FROM academic_terms t
LEFT JOIN academic_term_policies p ON p.term_id = t.term_id
WHERE t.is_active = 1;
```

---

### Scene 4.5 — Program shift workflow

| | |
|---|---|
| **Visual** | Student Manager → Program shift → `/faculty/program-shifts` → `/admin/program-shifts` |
| **Narration** | "Program shifts follow the same approval loop — no silent database changes." |
| **Checklist** | 5.3 Pass |

**MySQL — shift requests:**

```sql
USE eacdb;

SELECT request_id, student_number, from_program_code, to_program_code, status, requested_at
FROM student_program_shift_requests
ORDER BY requested_at DESC LIMIT 5;
```

---

### Scene 4.6 — Withdrawal analytics

| | |
|---|---|
| **Visual** | `/admin/withdrawals/report` |
| **Narration** | "Management can aggregate withdrawal reasons and timing buckets from this report." |
| **Checklist** | 5.4 Pass |

---

# ACT 5 — Grading & Holds (8 min)

*Checklist: 6.2, 7.2, 7.5, 7.6, 7.8*

---

### Scene 5.1 — Grading scheme

| | |
|---|---|
| **Visual** | `/admin/settings` → Grading Scheme section |
| **Narration** | "Grade weighting is configurable — class standing versus exam — and applied during faculty encoding." |
| **Checklist** | 6.2 Pass |

**MySQL:**

```sql
USE eacdb;

SELECT scheme_id, program_code, class_standing_percent, exam_percent, base_scale
FROM grading_schemes;
```

---

### Scene 5.2 — Student holds

| | |
|---|---|
| **Visual** | Student Manager `SPRINT-DEMO-2026-001` → Holds section |
| **Narration** | "OSA, Library, Registrar, or Finance can tag holds. Active holds block portal grades and load views." |
| **Checklist** | 7.5 Pass, 7.6 Pass |

**MySQL — add Library hold live:**

```sql
USE eacdb;

INSERT INTO student_holds (student_number, office, reason, active, created_by)
VALUES ('SPRINT-DEMO-2026-001', 'Library', 'Unreturned reference book — demo', 1, 'presenter');

SELECT hold_id, office, active, reason FROM student_holds
WHERE student_number = 'SPRINT-DEMO-2026-001';
```

**MySQL — clear hold after demo:**

```sql
USE eacdb;

UPDATE student_holds SET active = 0, cleared_by = 'presenter', cleared_at = NOW()
WHERE student_number = 'SPRINT-DEMO-2026-001' AND office = 'Library' AND active = 1;
```

---

### Scene 5.3 — Dean evaluation checklist

| | |
|---|---|
| **Visual** | `/dean/student-evaluation?studentNumber=SPRINT-DEMO-2026-001` |
| **Narration** | "Deans see a curriculum checklist — black for passed, red for failed — to support promotion decisions." |
| **Checklist** | 7.8 Pass |

---

### Scene 5.4 — Scholarship filter note

| | |
|---|---|
| **Visual** | Scholarship review screen (if time) |
| **Narration** | "Withdrawn students are excluded from scholarship candidate lists automatically." |
| **Checklist** | 7.2 Pass |

---

# ACT 6 — Enrollment Periods & Finance Policy (5 min)

*Checklist: 2.8, 2.9, 2.6, 8.x*

---

### Scene 6.1 — Finance Policy dates

| | |
|---|---|
| **Visual** | `/admin/finance-policy` |
| **Narration** | "Enrollment open and close dates control enlistment. Add/drop close locks schedule changes and new withdrawals." |
| **Checklist** | 2.8 Pass, 2.9 Pass |

**MySQL — current dates:**

```sql
USE eacdb;

SELECT setting_key, setting_value
FROM system_settings
WHERE setting_key IN (
  'ENROLLMENT_OPEN_DATE', 'ENROLLMENT_CLOSE_DATE', 'ADD_DROP_CLOSE_DATE',
  'LATE_ENROLLMENT_FEE_ENABLED'
)
ORDER BY setting_key;
```

**MySQL — simulate closed add/drop (demo only, revert after):**

```sql
USE eacdb;

-- Save original first!
SELECT setting_value INTO @saved_add_drop FROM system_settings
WHERE setting_key = 'ADD_DROP_CLOSE_DATE';

UPDATE system_settings SET setting_value = '2020-01-01'
WHERE setting_key = 'ADD_DROP_CLOSE_DATE';

-- Now try enlistment in UI → should block. Then revert:
UPDATE system_settings SET setting_value = @saved_add_drop
WHERE setting_key = 'ADD_DROP_CLOSE_DATE';
```

---

### Scene 6.2 — Installment override guard

| | |
|---|---|
| **Visual** | Student Manager → installment section (ADMIN only) |
| **Narration** | "Installment overrides are ADMIN-only here; Cashier owns official installment plans." |
| **Checklist** | 2.6 Pass |

---

# ACT 7 — Closing (5 min)

---

### Scene 7.1 — Requirements scorecard

| | |
|---|---|
| **Visual** | `REQUIREMENTS_EVALUATION_CHECKLIST.md` projected |
| **Narration** | "Of 40 evaluator items, 28 pass in Registrar scope, 16 partial where Enrollment or Admission owns the flow, 3 external to Cashier." |

---

### Scene 7.2 — Production path

| | |
|---|---|
| **Visual** | `PRODUCTION_GO_LIVE_CHECKLIST.md` |
| **Narration** | "Demo-ready today; production requires UAT sign-off, official fees, HTTPS, and secrets — documented in the go-live checklist." |

---

### Scene 7.3 — Q&A + sign-off

| | |
|---|---|
| **Visual** | Blank evaluator sign-off slide / form |
| **Narration** | "Questions?" |

---

# Appendix A — SQL file index

| When | File | Command |
|------|------|---------|
| **All-in-one demo prep** | `db/demo_scripts/STORYBOARD_SQL_ALL_IN_ONE.sql` | `RUN_STORYBOARD_DEMO_PREP.cmd` |
| Fresh DB (destructive) | `setup/RUN_FRESH_SETUP.cmd` | includes sprint schema + seed |
| Upgrade existing DB | `db/migrations/20260619_sprint_1_10_upgrade.sql` | `db/migrations/RUN_UPGRADE.cmd` |
| Withdrawal UAT student | `db/demo_scripts/16_withdrawal_uat_seed.sql` | see Act 4 Scene 4.1 |
| Verify sprint features | `db/sql_manual/12_verify_sprint_features.sql` | after any migration |
| Scholarship demo | `db/sql_manual/08_scholarship_demo_seed.sql` | optional Act 5.4 |

---

# Appendix B — URL cue cards

| Scene | URL |
|-------|-----|
| Programs | http://localhost:8083/registrar/admin/programs |
| Course catalog | http://localhost:8083/registrar/admin/course-catalog |
| Class scheduling | http://localhost:8083/registrar/admin/class-scheduling?view=blocks |
| Slot monitoring | http://localhost:8083/registrar/admin/slot-monitoring |
| Student Profile | http://localhost:8083/registrar/admin/student-manager?username=SPRINT-DEMO-2026-001 |
| Print TOR | http://localhost:8083/registrar/admin/print-tor |
| Dean withdrawals | http://localhost:8083/registrar/faculty/withdrawals |
| Registrar withdrawals | http://localhost:8083/registrar/admin/withdrawals |
| Withdrawal report | http://localhost:8083/registrar/admin/withdrawals/report |
| Program shifts (Dean) | http://localhost:8083/registrar/faculty/program-shifts |
| Program shifts (Reg) | http://localhost:8083/registrar/admin/program-shifts |
| Settings | http://localhost:8083/registrar/admin/settings |
| Finance policy | http://localhost:8083/registrar/admin/finance-policy |
| Dean evaluation | http://localhost:8083/registrar/dean/student-evaluation?studentNumber=SPRINT-DEMO-2026-001 |

---

# Appendix C — Presenter sign-off

```
Presenter: ___________________  Date: ___________
Demo GO / NO-GO: ___________
Notes:


Evaluator: ___________________  Date: ___________
```
