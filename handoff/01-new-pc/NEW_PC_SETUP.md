# CAPSS — New PC Setup Checklist



Use this when copying the project to **another machine**. Read **`../03-agent-dev/AGENT_HANDOVER_JUN2026.md`** for finance/status context.



---



## 1. Copy these folders to the new PC



| Folder | Purpose |

|--------|---------|

| `registrar/` | Registrar source, `handoff/`, `db/fix`, all demo SQL |

| `enrollment3/` | Enrollment/cashier source (`mvnw.cmd` here) |

| Admission source (often same repo as enrollment or `AdmissionEAC/`) | Builds `admission.war` |



You do **not** need: old Tomcat folder, old `eacdb` dump, hotfix SQL, or Cursor chat history.



---



## 2. Install on the new PC



1. **JDK 17 or 21** — add to PATH  

2. **MySQL 8** (or MariaDB 10.4+) — port **3306**, root password **blank** (matches default `application.properties`)  

3. **MySQL Workbench**  

4. **Apache Tomcat 10.1.x** — port **8080**  

5. **Maven** — optional if you use `enrollment3/mvnw.cmd`



---



## 3. Database (run in Workbench, in order)



All paths relative to `registrar/db/`:



| # | Script |

|---|--------|

| 1 | **`fix`** — full schema (drops all data) |

| 2 | `capss-demo-required/01_setup/01_fresh_demo_bootstrap.sql` |

| 3 | `capss-demo-required/01_setup/02_bsit_full_align_term_and_curriculum.sql` |

| 4 | `capss-demo-required/01_setup/03_seed_program_fees_full_lifecycle.sql` |

| 5 | **One** in `capss-demo-required/02_demo_seed_pick_one/` — `demo_full_lifecycle.sql` (Maria) **or** `demo_elon_2026-0004_fresh.sql` (Elon) **or** `00_demo_applicant_setup.sql` (live admission) |



**Do not run** on fresh install: `fix_elon_*`, `fix_zuckerberg_*`, `03_fee_term_versioning_schema.sql` (unless using legacy fee-rates mode).



Verify after step 1:



```sql

USE eacdb;

SELECT DATA_TYPE FROM information_schema.COLUMNS

WHERE TABLE_SCHEMA='eacdb' AND TABLE_NAME='student_enlistments' AND COLUMN_NAME='student_id';

-- expect: varchar

```



Details: **`../02-panel-demo/CAPSS_Deployment_and_Demo_Manual.md`** Section 3 · **`../05-demo-guides/README_DEMO_SQL.md`**



---



## 4. Build and deploy WARs



From the new PC (adjust paths):



```powershell

cd "<path>\enrollment3"

.\mvnw.cmd clean package -DskipTests



cd "<path>\enrollment3"

.\mvnw.cmd -f "<path>\registrar\pom.xml" clean package -DskipTests

```



Copy to `<tomcat>\webapps\`:



| Built artifact | Deploy as |

|----------------|-----------|

| `enrollment3\target\enrollment.war` (or `*-SNAPSHOT.war`) | `enrollment.war` |

| `registrar\target\registrar-0.0.1-SNAPSHOT.war` | `registrar.war` |

| Admission build output | `admission.war` |



Run `<tomcat>\bin\startup.bat`. Open:



- http://localhost:8080/admission  

- http://localhost:8080/enrollment  

- http://localhost:8080/registrar  



Staff logins: **`admin` / `1234`**, **`cashier` / `1234`**, **`prof` / `1234`**



---



## 5. Optional: finance QA personas



After steps 1–4 above (do **not** skip bootstrap/fees):



```

db/demo_scripts/00_finance_demo_reset.sql

db/demo_scripts/10_seed_finance_demo_personas.sql

```



See **`../05-demo-guides/FRESH_FINANCE_DEMO.md`**.



---



## 6. Known limitation (Jun 2026)



Forward **net** totals are fixed in source. **Historical ledger** after term advance may not match term-close snapshot until `student_term_closes` is implemented — see **`../03-agent-dev/AGENT_HANDOVER_JUN2026.md` §8**.



---



## 7. Doc index



All under `registrar/handoff/` — see **`../README.md`** for the full folder map.



| Path | Use |

|------|-----|

| `01-new-pc/NEW_PC_SETUP.md` | This checklist |

| `START_HERE.txt` | Plain-text entry point |

| `03-agent-dev/AGENT_HANDOVER_JUN2026.md` | Agent/dev status & next tasks |

| `02-panel-demo/CAPSS_Deployment_and_Demo_Manual.md` | Full panel demo script |

| `../db/capss-demo-required/` | CAPSS demo SQL (setup, seeds, grades) |
| `05-demo-guides/README_DEMO_SQL.md` | SQL order & grade scripts |

| `04-database/SQL_README.md` | SQL inventory |

| `05-demo-guides/FINANCE_FIX_STEPS.md` | Build + finance rules |


