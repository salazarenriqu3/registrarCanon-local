# Deployment Runbook

Date: 2026-06-19  
Application: IUIMS Registrar (`registrar-0.0.1-SNAPSHOT.war`)  
Context path: `/registrar`  
Default port: `8083`

Use with [`PRODUCTION_GO_LIVE_CHECKLIST.md`](PRODUCTION_GO_LIVE_CHECKLIST.md) for sign-off gates.

---

## 1. Prerequisites

| Requirement | Notes |
|-------------|-------|
| JDK 17 | `java -version` |
| Maven 3.9+ | Build WAR |
| MySQL/MariaDB 10.x+ | Shared `eacdb` |
| Enrollment app | Port 8082 for cross-app UAT |
| Reverse proxy | HTTPS recommended for prod |

---

## 2. Environment matrix

| Variable | Demo | Staging / Prod |
|----------|------|----------------|
| `SPRING_PROFILES_ACTIVE` | *(unset)* | `prod` |
| `SPRING_DATASOURCE_URL` | default localhost | JDBC URL to shared DB |
| `SPRING_DATASOURCE_USERNAME` | `root` | dedicated app user |
| `SPRING_DATASOURCE_PASSWORD` | empty (dev only) | **required** |
| `APP_UPLOAD_DIR` | optional | shared with Admission |
| `REGISTRAR_SHARED_UPLOAD_DIR` | optional | shared uploads root |

---

## 3. Database setup paths

### A. New demo machine (destructive)

```cmd
cd <workspace-root>
registrar\setup\RUN_FRESH_SETUP.cmd
mysql -u root eacdb < registrar\db\demo_scripts\19_sprint_features_demo_seed.sql
mysql -u root eacdb < registrar\db\sql_manual\12_verify_sprint_features.sql
```

### B. Existing database upgrade (non-destructive)

```cmd
registrar\db\migrations\RUN_UPGRADE.cmd
mysql -u root eacdb < registrar\db\demo_scripts\19_sprint_features_demo_seed.sql
mysql -u root eacdb < registrar\db\sql_manual\12_verify_sprint_features.sql
```

Sign off: [`db/MIGRATION_SIGNOFF.md`](../../db/MIGRATION_SIGNOFF.md)

### C. Packaged demo bundle

```cmd
registrar\docs\demo\final-demo-package\04_RUNNERS\01_CHECK_MACHINE.cmd
registrar\docs\demo\final-demo-package\02_FRESH_DATABASE\RUN_FRESH_DATABASE.cmd
registrar\docs\demo\final-demo-package\04_RUNNERS\08_LOAD_SPRINT_DEMO_DATA.cmd
```

---

## 4. Build

```cmd
cd registrar
mvn -q -DskipTests package
```

Artifact: `target/registrar-0.0.1-SNAPSHOT.war`

Tests (CI gate):

```cmd
mvn test -Dtest=!ModulithTests
```

---

## 5. Deploy to Tomcat

1. Stop Tomcat
2. Remove old `registrar*.war` and exploded folder from `webapps/`
3. Copy new WAR to `webapps/registrar.war` (or configure context)
4. Set environment variables (see §2)
5. Start Tomcat
6. Confirm log line: `Started RegistrarSubsystem`

### Spring Boot standalone (dev / pilot)

```cmd
set SPRING_PROFILES_ACTIVE=prod
set SPRING_DATASOURCE_PASSWORD=<secret>
mvn spring-boot:run
```

---

## 6. Post-deploy smoke (15 minutes)

| # | URL | Expected |
|---|-----|----------|
| 1 | `/registrar/login` | Login page loads |
| 2 | `/registrar/admin/settings` | Active term + readiness |
| 3 | `/registrar/admin/finance-policy` | Enrollment dates visible |
| 4 | `/registrar/admin/programs` | Program list loads |
| 5 | `/registrar/admin/slot-monitoring` | Section grid loads |
| 6 | `/registrar/admin/student-manager?username=SPRINT-DEMO-2026-001` | Holds section visible |
| 7 | `/registrar/faculty/withdrawals` | Dean queue loads |
| 8 | `/registrar/dean/student-evaluation?studentNumber=SPRINT-DEMO-2026-001` | Checklist loads |

Demo credentials (rotate before prod): `admin` / `1234`

---

## 7. Rollback

1. Stop Tomcat
2. Restore previous WAR from archive
3. Restore DB from backup ID recorded in release ticket
4. Restart Tomcat
5. Re-run smoke on previous version

Schema rollback: new columns are nullable; new tables can remain if they contain production data.

---

## 8. Related documents

| Document | Purpose |
|----------|---------|
| [`PRODUCTION_GO_LIVE_CHECKLIST.md`](PRODUCTION_GO_LIVE_CHECKLIST.md) | Gate sign-off |
| [`REQUIREMENTS_EVALUATION_CHECKLIST.md`](REQUIREMENTS_EVALUATION_CHECKLIST.md) | 40-item evaluator sheet |
| [`DEMO_SCRIPT_SPRINT_FEATURES.md`](DEMO_SCRIPT_SPRINT_FEATURES.md) | Sprint feature demo script |
| [`CHECKLIST_TRACEABILITY.md`](CHECKLIST_TRACEABILITY.md) | Code evidence map |
| [`FINAL_DEMO_AND_TEST_MANUAL_20260618.md`](FINAL_DEMO_AND_TEST_MANUAL_20260618.md) | Full UAT manual |

---

## 9. Support contacts (fill before prod)

| Role | Contact |
|------|---------|
| Registrar lead | |
| DBA | |
| IT operations | |
| Enrollment app owner | |
