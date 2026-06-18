# EAC Registrar Final Demo Package

Package date: 2026-06-19  
Expected location: `registrar\docs\demo\final-demo-package`

This is the canonical, sorted package for setting up, building, demonstrating, testing, and handing over the Registrar-centered build.

**Sprint 1–10 update:** includes schema migration, demo seed SQL, evaluator checklist, deployment runbook, and production go-live gates.

## Folder map

| Folder | Purpose |
|---|---|
| `01_DOCUMENTATION` | Final system documentation, demo/UAT manual, handover, **deployment runbook**, **evaluator checklist** |
| `02_FRESH_DATABASE` | Self-contained destructive fresh database setup and all required SQL (includes sprint schema) |
| `03_TEST_DATA` | Sprint demo seed, verification SQL, scholarship/withdrawal UAT seeds |
| `04_RUNNERS` | Package validation, build, tests, app startup, preflight, **sprint demo load** |
| `05_MANIFEST` | Source mapping and SHA-256 integrity manifest |
| `06_EVIDENCE` | Blank execution/sign-off record for the demo machine |

## First terminal

Open PowerShell at the workspace root containing `registrar` and `enrollment3`.

```powershell
registrar\docs\demo\final-demo-package\04_RUNNERS\00_VERIFY_PACKAGE.cmd
registrar\docs\demo\final-demo-package\04_RUNNERS\01_CHECK_MACHINE.cmd
```

For a disposable machine/database only:

```powershell
registrar\docs\demo\final-demo-package\02_FRESH_DATABASE\RUN_FRESH_DATABASE.cmd
```

Warning: the fresh database command drops and recreates `eacdb`.

Then run:

```powershell
registrar\docs\demo\final-demo-package\04_RUNNERS\02_BUILD_ALL.cmd
registrar\docs\demo\final-demo-package\04_RUNNERS\03_RUN_REGISTRAR_TESTS.cmd
```

Start each application in its own terminal:

```powershell
registrar\docs\demo\final-demo-package\04_RUNNERS\04_START_REGISTRAR.cmd
registrar\docs\demo\final-demo-package\04_RUNNERS\05_START_ENROLLMENT.cmd
```

Load the current scholarship demonstration records when needed:

```powershell
registrar\docs\demo\final-demo-package\04_RUNNERS\07_LOAD_SCHOLARSHIP_TEST_DATA.cmd
```

Sprint 1–10 demo data (enrollment dates, holds, course types) is included in fresh DB setup. To reload on an existing database:

```powershell
registrar\docs\demo\final-demo-package\04_RUNNERS\08_LOAD_SPRINT_DEMO_DATA.cmd
```

Upgrade an existing database without full rebuild:

```powershell
registrar\docs\demo\final-demo-package\04_RUNNERS\09_RUN_SPRINT_MIGRATION.cmd
```

Read `01_DOCUMENTATION\DEMO_SCRIPT_SPRINT_FEATURES.md` for the sprint feature demo walkthrough.  
Read `01_DOCUMENTATION\FINAL_DEMO_AND_TEST_MANUAL_20260618.md` before presenting.

## Canonical boundaries

- Active demo term: `1120242025`, term id 1.
- Registrar irregular new-enrollee advising/pre-registration is retired and excluded.
- Demo fee values are not official production values.
- This package supports controlled demo/UAT, not production deployment.
