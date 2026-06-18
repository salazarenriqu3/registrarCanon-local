# Database Migrations

## Fresh install (destructive)

Use [`../setup/RUN_FRESH_SETUP.cmd`](../setup/RUN_FRESH_SETUP.cmd) — includes sprint schema at step 18.

## Upgrade existing database (non-destructive)

For staging or production databases that already have `eacdb` data:

```cmd
registrar\db\migrations\RUN_UPGRADE.cmd
```

Or manually:

```cmd
mysql -u root -p eacdb < registrar/db/migrations/20260619_sprint_1_10_upgrade.sql
```

Then verify:

```cmd
mysql -u root -p eacdb < registrar/db/sql_manual/12_verify_sprint_features.sql
```

## Optional demo data (after bootstrap or upgrade)

Loads enrollment period dates, sample holds, course types, and midterm policy for UAT:

```cmd
mysql -u root -p eacdb < registrar/db/demo_scripts/19_sprint_features_demo_seed.sql
```

## Sign-off

Complete [`../MIGRATION_SIGNOFF.md`](../MIGRATION_SIGNOFF.md) before promoting to production.
