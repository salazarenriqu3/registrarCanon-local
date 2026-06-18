# IUIMS Registrar System

Spring Boot registrar module for the IUIMS/CAPSS stack — enrollment, curriculum, grading, finance, scholarships, and admin portals.

## Quick start

**Prerequisites:** JDK 17, Maven, MariaDB/MySQL

From the project root:

```cmd
setup\CHECK_PREREQUISITES.cmd
setup\RUN_FRESH_SETUP.cmd
mvn spring-boot:run
```

Default URL: http://localhost:8083/registrar  
Demo login: `admin` / `1234`

## Repository layout

| Path | Purpose |
|------|---------|
| `src/` | Application code (Java, Thymeleaf templates, config) |
| `db/` | SQL schema, seeds, demo scripts, manual patches |
| `setup/` | Fresh database bootstrap (`RUN_FRESH_SETUP.cmd`) |
| `docs/` | Architecture, business logic, handoff, and demo documentation |
| `scripts/` | Runnable helper scripts |
| `tools/archive/` | Retired one-off migration/fix scripts |

## Documentation

| Start here | Description |
|------------|-------------|
| [`docs/handoff/START_HERE_NEW_PC_HANDOFF.md`](docs/handoff/START_HERE_NEW_PC_HANDOFF.md) | Current handover entry point |
| [`docs/demo/final-demo-package/00_START_HERE.md`](docs/demo/final-demo-package/00_START_HERE.md) | Packaged demo/UAT bundle |
| [`docs/handoff/COMPLETE_FRESH_SETUP_AND_DEMO_GUIDE.md`](docs/handoff/COMPLETE_FRESH_SETUP_AND_DEMO_GUIDE.md) | Full setup and demo guide |
| [`docs/handoff/PRODUCTION_GO_LIVE_CHECKLIST.md`](docs/handoff/PRODUCTION_GO_LIVE_CHECKLIST.md) | Production deployment gates and sign-off |
| [`setup/README.md`](setup/README.md) | Bootstrap commands and folder map |
| [`docs/README.md`](docs/README.md) | Documentation index |

Legacy CAPSS docs: [`docs/handoff/legacy-capss/`](docs/handoff/legacy-capss/)

## Build and test

```cmd
mvn test
mvn test -Dtest=!ModulithTests
mvn spring-boot:run
```

Production profile (requires env vars — see `docs/handoff/PRODUCTION_GO_LIVE_CHECKLIST.md`):

```cmd
set SPRING_PROFILES_ACTIVE=prod
set SPRING_DATASOURCE_PASSWORD=<secret>
mvn spring-boot:run
```

## Related apps

This module is designed to run alongside **enrollment3** (separate WAR) in a multi-app demo environment. See handoff docs for the full stack layout.
