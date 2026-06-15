-- Copy global fallback S2 fee rows into exact term 1 (1120242025) for BSCPE + BSIT.
-- Clears the 8 "FALLBACK_ONLY" readiness warnings on /admin/term-fees?termId=1.
-- Safe to re-run: skips scopes that already have an exact term_id = 1 row.

USE eacdb;

INSERT INTO program_fee_settings (
    program_id, term_id, year_level, semester_number,
    fee_tuition_per_unit, fee_lec_per_unit, fee_lab_per_unit, fee_comp_per_unit, fee_rle_per_unit,
    fee_misc_registration, fee_misc_library, fee_misc_medical, fee_misc_id, fee_misc_athletic,
    fee_misc_guidance, fee_misc_lms, fee_misc_insurance, fee_misc_cultural, fee_misc_av, fee_misc_energy,
    fee_other_id, fee_other_insurance, fee_other_comp, fee_other_dev,
    fee_other_late_enrollment, fee_other_add_drop, fee_other_installment,
    is_active
)
SELECT
    src.program_id, 1, src.year_level, src.semester_number,
    src.fee_tuition_per_unit, src.fee_lec_per_unit, src.fee_lab_per_unit, src.fee_comp_per_unit, src.fee_rle_per_unit,
    src.fee_misc_registration, src.fee_misc_library, src.fee_misc_medical, src.fee_misc_id, src.fee_misc_athletic,
    src.fee_misc_guidance, src.fee_misc_lms, src.fee_misc_insurance, src.fee_misc_cultural, src.fee_misc_av, src.fee_misc_energy,
    src.fee_other_id, src.fee_other_insurance, src.fee_other_comp, src.fee_other_dev,
    src.fee_other_late_enrollment, src.fee_other_add_drop, src.fee_other_installment,
    1
FROM program_fee_settings src
JOIN programs p ON p.program_id = src.program_id
WHERE p.program_code IN ('BSCPE', 'BSIT')
  AND src.term_id IS NULL
  AND src.semester_number = 2
  AND src.year_level BETWEEN 1 AND 4
  AND src.is_active = 1
  AND NOT EXISTS (
      SELECT 1 FROM program_fee_settings exact
      WHERE exact.program_id = src.program_id
        AND exact.term_id = 1
        AND exact.year_level = src.year_level
        AND exact.semester_number = src.semester_number
        AND exact.is_active = 1
  );

SELECT p.program_code, pfs.year_level, pfs.semester_number, pfs.term_id,
       pfs.fee_tuition_per_unit, pfs.fee_misc_registration, pfs.fee_other_comp, pfs.fee_other_dev
FROM program_fee_settings pfs
JOIN programs p ON p.program_id = pfs.program_id
WHERE p.program_code IN ('BSCPE', 'BSIT')
  AND pfs.term_id = 1
  AND pfs.semester_number = 2
  AND pfs.is_active = 1
ORDER BY p.program_code, pfs.year_level;
