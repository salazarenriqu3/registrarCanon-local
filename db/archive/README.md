# Archived SQL (legacy upgrades only)

Do **not** run these on a fresh install. Use `db/fix` instead.

| File | Superseded by |
|------|----------------|
| `hotfix_*.sql` | End of `db/fix` |
| `01_schema_eacdb_unified.sql` | `db/fix` |
| `02_seed_eacdb_test_data.sql` | `db/fix` |
| `05_admission_eacdb_align.sql` | `db/fix` + `db/eacdb_cross_system_schema.sql` |

**Existing DB from before May 27 2026:** run `db/eacdb_cross_system_schema.sql` once (not these hotfixes individually).
