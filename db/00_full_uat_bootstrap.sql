-- =============================================================================

-- EACDB — FULL UAT BOOTSTRAP (forwards to registrar/setup)

-- =============================================================================

-- Prefer: registrar\setup\RUN_FRESH_SETUP.cmd  (from project root)

-- Active term after run: 1120242025 (A.Y. 2024-25, 1st Semester)

-- =============================================================================



SOURCE registrar/db/fix;

SOURCE enrollment3/src/main/resources/sql/01_enlistment_status_schema.sql;

SOURCE registrar/db/04_seed_full_curriculum.sql;

SOURCE registrar/db/demo_scripts/00_upsert_academic_terms_calendar.sql;

SOURCE registrar/db/capss-demo-required/01_setup/03_seed_program_fees_full_lifecycle.sql;

SOURCE registrar/docs/business_logic/schema_migration_001.sql;

SOURCE registrar/db/manual_patches/20260608_retire_empty_curriculum_blockers.sql;

SOURCE registrar/db/seed_all_program_block_sections_calendar.sql;

SOURCE registrar/db/seed_block_offerings.sql;

SOURCE registrar/db/seed_irregular_open_sections.sql;

SOURCE registrar/db/seed_faculty_professors_and_grading.sql;

SOURCE registrar/db/seed_all_class_schedules.sql;

SOURCE registrar/setup/sql/01_activate_term_2425_s1.sql;

SOURCE registrar/setup/sql/02_materialize_term_fees.sql;

SOURCE registrar/setup/sql/05_materialize_all_calendar_term_fees.sql;

SOURCE registrar/setup/sql/03_assign_prof_cruz_demo.sql;

SOURCE registrar/setup/sql/04_verify_readiness.sql;



USE eacdb;

SELECT 'ACTIVE TERM' AS check_name, term_id, term_code, is_active

FROM academic_terms WHERE is_active = 1;

SELECT 'BLOCK SECTIONS' AS check_name, COUNT(*) AS cnt

FROM class_sections cs

JOIN academic_terms t ON t.term_id = cs.term_id AND t.is_active = 1

WHERE cs.section_code REGEXP '-[0-9]-[0-9]-[A-D]$';

