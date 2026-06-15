-- =============================================================================
-- 04_demo_fee_rates_two_terms.sql
-- Demo seed: two terms with different rates (proves term-based fee changes)
--
-- Requires: 03_fee_term_versioning_schema.sql
-- =============================================================================
USE eacdb;

-- Pick two term_ids: active + next (if available)
SET @term_a = (
  SELECT term_id FROM academic_terms
  WHERE is_active = 1 OR UPPER(COALESCE(status,'')) = 'ACTIVE'
  ORDER BY term_id DESC LIMIT 1
);
SET @term_b = (
  SELECT term_id FROM academic_terms
  WHERE term_id > @term_a
  ORDER BY term_id ASC LIMIT 1
);
SET @term_b = COALESCE(@term_b, (SELECT MAX(term_id) FROM academic_terms));

SET @ft_tuition = (SELECT fee_type_id FROM fee_types WHERE fee_code = 'TUITION_PER_UNIT');
SET @ft_rle_hr  = (SELECT fee_type_id FROM fee_types WHERE fee_code = 'RLE_RATE_PER_HOUR');

-- Optional demo MISC/OTHER items (editable per term via UI after this)
INSERT IGNORE INTO fee_types (fee_code, fee_name, kind, unit_basis) VALUES
('MISC_ID', 'Identification Card', 'CHARGE', 'FLAT'),
('MISC_INSURANCE', 'Insurance', 'CHARGE', 'FLAT'),
('OTHER_COMP_HANDS_ON', 'Computer Hands-On', 'CHARGE', 'FLAT');

SET @ft_misc_id = (SELECT fee_type_id FROM fee_types WHERE fee_code = 'MISC_ID');
SET @ft_misc_ins = (SELECT fee_type_id FROM fee_types WHERE fee_code = 'MISC_INSURANCE');
SET @ft_other_comp = (SELECT fee_type_id FROM fee_types WHERE fee_code = 'OTHER_COMP_HANDS_ON');

-- TERM A (current) - BSN (RLE test) and BSIT (tuition test)
INSERT INTO program_fee_rates (term_id, program_code, fee_type_id, amount, is_active) VALUES
(@term_a, 'BSN',  @ft_tuition, 1773.00, 1),
(@term_a, 'BSN',  @ft_rle_hr,  87.00, 1),
(@term_a, 'BSN',  @ft_misc_id, 150.00, 1),
(@term_a, 'BSN',  @ft_misc_ins, 400.00, 1),
(@term_a, 'BSN',  @ft_other_comp, 0.00, 1),

(@term_a, 'BSIT', @ft_tuition, 450.00, 1),
(@term_a, 'BSIT', @ft_misc_id, 150.00, 1),
(@term_a, 'BSIT', @ft_misc_ins, 400.00, 1),
(@term_a, 'BSIT', @ft_other_comp, 13930.00, 1)
ON DUPLICATE KEY UPDATE amount = VALUES(amount), is_active = 1;

-- TERM B (next) - change rates to prove term-versioning
INSERT INTO program_fee_rates (term_id, program_code, fee_type_id, amount, is_active) VALUES
(@term_b, 'BSN',  @ft_tuition, 1850.00, 1),
(@term_b, 'BSN',  @ft_rle_hr,  95.00, 1),
(@term_b, 'BSN',  @ft_misc_id, 200.00, 1),
(@term_b, 'BSN',  @ft_misc_ins, 450.00, 1),
(@term_b, 'BSN',  @ft_other_comp, 0.00, 1),

(@term_b, 'BSIT', @ft_tuition, 475.00, 1),
(@term_b, 'BSIT', @ft_misc_id, 200.00, 1),
(@term_b, 'BSIT', @ft_misc_ins, 450.00, 1),
(@term_b, 'BSIT', @ft_other_comp, 14930.00, 1)
ON DUPLICATE KEY UPDATE amount = VALUES(amount), is_active = 1;

SELECT @term_a AS term_a, @term_b AS term_b;
SELECT pfr.program_code, pfr.term_id, ft.fee_code, pfr.amount
FROM program_fee_rates pfr
JOIN fee_types ft ON pfr.fee_type_id = ft.fee_type_id
WHERE pfr.term_id IN (@term_a, @term_b)
  AND pfr.program_code IN ('BSN','BSIT')
ORDER BY pfr.program_code, pfr.term_id, ft.fee_code;

