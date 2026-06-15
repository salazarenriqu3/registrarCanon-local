-- BSBio Y3/Y4 exact fees for active term 2 (2120242025).
-- Copies term 1 official rows when term 2 scopes are missing (RLE-primary program).
-- Safe to re-run.

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
    src.program_id, 2, src.year_level, src.semester_number,
    src.fee_tuition_per_unit, src.fee_lec_per_unit, src.fee_lab_per_unit, src.fee_comp_per_unit, src.fee_rle_per_unit,
    src.fee_misc_registration, src.fee_misc_library, src.fee_misc_medical, src.fee_misc_id, src.fee_misc_athletic,
    src.fee_misc_guidance, src.fee_misc_lms, src.fee_misc_insurance, src.fee_misc_cultural, src.fee_misc_av, src.fee_misc_energy,
    src.fee_other_id, src.fee_other_insurance, src.fee_other_comp, src.fee_other_dev,
    src.fee_other_late_enrollment, src.fee_other_add_drop, src.fee_other_installment,
    1
FROM program_fee_settings src
JOIN programs p ON p.program_id = src.program_id
WHERE p.program_code = 'BSBio'
  AND src.term_id = 1
  AND src.year_level IN (3, 4)
  AND src.semester_number IN (1, 2)
  AND src.is_active = 1
  AND (COALESCE(src.fee_tuition_per_unit, 0) > 0
       OR COALESCE(src.fee_lec_per_unit, 0) > 0
       OR COALESCE(src.fee_rle_per_unit, 0) > 0)
  AND NOT EXISTS (
      SELECT 1 FROM program_fee_settings exact
      WHERE exact.program_id = src.program_id
        AND exact.term_id = 2
        AND exact.year_level = src.year_level
        AND exact.semester_number = src.semester_number
        AND exact.is_active = 1
  );

SELECT p.program_code, pfs.year_level, pfs.semester_number,
       pfs.fee_tuition_per_unit, pfs.fee_rle_per_unit, pfs.fee_misc_registration
FROM program_fee_settings pfs
JOIN programs p ON p.program_id = pfs.program_id
WHERE p.program_code = 'BSBio' AND pfs.term_id = 2 AND pfs.year_level IN (3, 4)
ORDER BY pfs.year_level, pfs.semester_number;
