-- Materialize exact program_fee_settings rows after demo fee seed + migration.
-- Safe to re-run. Run after 01_calendar_and_active_term.sql (active term = 2120242025 / term_id 2).
USE eacdb;

-- 1) Term 1: BSCPE/BSIT curriculum slot S2 from global (NULL) templates
INSERT INTO program_fee_settings (
    program_id, term_id, year_level, semester_number,
    fee_tuition_per_unit, fee_lec_per_unit, fee_lab_per_unit, fee_comp_per_unit, fee_rle_per_unit,
    fee_misc_registration, fee_misc_library, fee_misc_medical, fee_misc_id, fee_misc_athletic,
    fee_misc_guidance, fee_misc_lms, fee_misc_insurance, fee_misc_cultural, fee_misc_av, fee_misc_energy,
    fee_other_id, fee_other_insurance, fee_other_comp, fee_other_dev,
    fee_other_late_enrollment, fee_other_add_drop, fee_other_installment, is_active
)
SELECT
    src.program_id, 1, src.year_level, src.semester_number,
    src.fee_tuition_per_unit, src.fee_lec_per_unit, src.fee_lab_per_unit, src.fee_comp_per_unit, src.fee_rle_per_unit,
    src.fee_misc_registration, src.fee_misc_library, src.fee_misc_medical, src.fee_misc_id, src.fee_misc_athletic,
    src.fee_misc_guidance, src.fee_misc_lms, src.fee_misc_insurance, src.fee_misc_cultural, src.fee_misc_av, src.fee_misc_energy,
    src.fee_other_id, src.fee_other_insurance, src.fee_other_comp, src.fee_other_dev,
    src.fee_other_late_enrollment, src.fee_other_add_drop, src.fee_other_installment, 1
FROM program_fee_settings src
JOIN programs p ON p.program_id = src.program_id
WHERE p.program_code IN ('BSCPE', 'BSIT')
  AND src.term_id IS NULL AND src.semester_number = 2 AND src.year_level BETWEEN 1 AND 4 AND src.is_active = 1
  AND NOT EXISTS (
      SELECT 1 FROM program_fee_settings exact
      WHERE exact.program_id = src.program_id AND exact.term_id = 1
        AND exact.year_level = src.year_level AND exact.semester_number = src.semester_number AND exact.is_active = 1
  );

-- 2) Active term (2120242025): copy missing exact rows from previous term (1120242025 / term_id 1)
INSERT INTO program_fee_settings (
    program_id, term_id, year_level, semester_number,
    fee_tuition_per_unit, fee_lec_per_unit, fee_lab_per_unit, fee_comp_per_unit, fee_rle_per_unit,
    fee_misc_registration, fee_misc_library, fee_misc_medical, fee_misc_id, fee_misc_athletic,
    fee_misc_guidance, fee_misc_lms, fee_misc_insurance, fee_misc_cultural, fee_misc_av, fee_misc_energy,
    fee_other_id, fee_other_insurance, fee_other_comp, fee_other_dev,
    fee_other_late_enrollment, fee_other_add_drop, fee_other_installment, is_active
)
SELECT
    src.program_id, tgt.term_id, src.year_level, src.semester_number,
    src.fee_tuition_per_unit, src.fee_lec_per_unit, src.fee_lab_per_unit, src.fee_comp_per_unit, src.fee_rle_per_unit,
    src.fee_misc_registration, src.fee_misc_library, src.fee_misc_medical, src.fee_misc_id, src.fee_misc_athletic,
    src.fee_misc_guidance, src.fee_misc_lms, src.fee_misc_insurance, src.fee_misc_cultural, src.fee_misc_av, src.fee_misc_energy,
    src.fee_other_id, src.fee_other_insurance, src.fee_other_comp, src.fee_other_dev,
    src.fee_other_late_enrollment, src.fee_other_add_drop, src.fee_other_installment, 1
FROM program_fee_settings src
JOIN programs p ON p.program_id = src.program_id AND COALESCE(p.active_status, 1) = 1
JOIN academic_terms tgt ON tgt.term_code = '2120242025'
JOIN academic_terms prev ON prev.term_code = '1120242025'
WHERE src.term_id = prev.term_id AND src.is_active = 1
  AND (COALESCE(src.fee_tuition_per_unit, 0) > 0 OR COALESCE(src.fee_lec_per_unit, 0) > 0 OR COALESCE(src.fee_rle_per_unit, 0) > 0)
  AND NOT EXISTS (
      SELECT 1 FROM program_fee_settings exact
      WHERE exact.program_id = src.program_id AND exact.term_id = tgt.term_id
        AND exact.year_level = src.year_level AND exact.semester_number = src.semester_number AND exact.is_active = 1
  );

-- 3) Y3/Y4 gaps (e.g. BSBio only seeded through Y2): copy active-term Y2 row per semester
INSERT INTO program_fee_settings (
    program_id, term_id, year_level, semester_number,
    fee_tuition_per_unit, fee_lec_per_unit, fee_lab_per_unit, fee_comp_per_unit, fee_rle_per_unit,
    fee_misc_registration, fee_misc_library, fee_misc_medical, fee_misc_id, fee_misc_athletic,
    fee_misc_guidance, fee_misc_lms, fee_misc_insurance, fee_misc_cultural, fee_misc_av, fee_misc_energy,
    fee_other_id, fee_other_insurance, fee_other_comp, fee_other_dev,
    fee_other_late_enrollment, fee_other_add_drop, fee_other_installment, is_active
)
SELECT
    src.program_id, src.term_id, yl.n, src.semester_number,
    src.fee_tuition_per_unit, src.fee_lec_per_unit, src.fee_lab_per_unit, src.fee_comp_per_unit, src.fee_rle_per_unit,
    src.fee_misc_registration, src.fee_misc_library, src.fee_misc_medical, src.fee_misc_id, src.fee_misc_athletic,
    src.fee_misc_guidance, src.fee_misc_lms, src.fee_misc_insurance, src.fee_misc_cultural, src.fee_misc_av, src.fee_misc_energy,
    src.fee_other_id, src.fee_other_insurance, src.fee_other_comp, src.fee_other_dev,
    src.fee_other_late_enrollment, src.fee_other_add_drop, src.fee_other_installment, 1
FROM program_fee_settings src
JOIN programs p ON p.program_id = src.program_id AND COALESCE(p.active_status, 1) = 1
JOIN academic_terms tgt ON tgt.term_code = '2120242025' AND src.term_id = tgt.term_id
CROSS JOIN (SELECT 3 AS n UNION SELECT 4 AS n) yl
WHERE src.year_level = 2 AND src.semester_number IN (1, 2) AND src.is_active = 1
  AND (COALESCE(src.fee_tuition_per_unit, 0) > 0 OR COALESCE(src.fee_lec_per_unit, 0) > 0 OR COALESCE(src.fee_rle_per_unit, 0) > 0)
  AND NOT EXISTS (
      SELECT 1 FROM program_fee_settings exact
      WHERE exact.program_id = src.program_id AND exact.term_id = src.term_id
        AND exact.year_level = yl.n AND exact.semester_number = src.semester_number AND exact.is_active = 1
  );

SELECT 'FEE READINESS active term' AS check_name,
       SUM(CASE WHEN exact.fee_setting_id IS NULL THEN 1
                WHEN COALESCE(exact.fee_tuition_per_unit,0)=0 AND COALESCE(exact.fee_lec_per_unit,0)=0 AND COALESCE(exact.fee_rle_per_unit,0)=0 THEN 1
                ELSE 0 END) AS unresolved_scopes,
       COUNT(*) AS scopes_checked
FROM programs p
CROSS JOIN (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) yl
CROSS JOIN (SELECT 1 n UNION SELECT 2) sem
JOIN academic_terms t ON t.term_code = '2120242025'
LEFT JOIN program_fee_settings exact
  ON exact.program_id = p.program_id AND exact.term_id = t.term_id
 AND exact.year_level = yl.n AND exact.semester_number = sem.n AND exact.is_active = 1
WHERE COALESCE(p.active_status, 1) = 1;
