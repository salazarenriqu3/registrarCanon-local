-- =============================================================================
-- Migrate legacy fee tables → program_fee_settings (Batch 3 unified fee model)
-- =============================================================================
-- Run when Registrar /admin/term-fees fails with:
--   Table 'eacdb.program_fee_settings' doesn't exist
--
-- Safe to re-run (idempotent). Requires existing program_general_fees /
-- program_specific_fees data (created by registrar/db/fix and fee seeds).
--
-- Full script: registrar/docs/business_logic/schema_migration_001.sql
-- =============================================================================

SOURCE registrar/docs/business_logic/schema_migration_001.sql;
