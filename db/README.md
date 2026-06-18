# Database Assets

## Primary paths

| Folder | Purpose |
|--------|---------|
| [`migrations/`](migrations/) | **Non-destructive upgrades** — sprint schema on existing DBs |
| [`capss-demo-required/`](capss-demo-required/) | **Main demo SQL** — follow `RUN_ORDER.txt` |
| [`demo_scripts/`](demo_scripts/) | Finance QA, UAT seeds, **storyboard all-in-one SQL** |
| [`sql_manual/`](sql_manual/) | Manual one-off patches (calendar, fees, scholarship seed) |
| [`manual_patches/`](manual_patches/) | Dated schema/data patches |
| [`manual_tests/`](manual_tests/) | Ad-hoc test schemas and seeds |
| [`archive/`](archive/) | Retired scripts including [`archive/root-legacy/`](archive/root-legacy/) |

## Fresh install (recommended)

Use the bootstrap in [`../setup/`](../setup/) rather than running root-level SQL directly.

```cmd
..\setup\RUN_FRESH_SETUP.cmd
```

## Upgrade existing database

```cmd
migrations\RUN_UPGRADE.cmd
```

## Storyboard presentation prep

```cmd
demo_scripts\RUN_STORYBOARD_DEMO_PREP.cmd
```

Or in MySQL Workbench: open `demo_scripts/STORYBOARD_SQL_ALL_IN_ONE.sql` and execute.  
Guide: [`../docs/handoff/PRESENTATION_STORYBOARD.md`](../docs/handoff/PRESENTATION_STORYBOARD.md)

## Legacy root SQL

Older monolithic scripts (`01_mega_schema_and_seed.sql`, `FULL_SCHOOL_PC_SETUP.sql`, etc.) were moved to [`archive/root-legacy/`](archive/root-legacy/) for reference only.
