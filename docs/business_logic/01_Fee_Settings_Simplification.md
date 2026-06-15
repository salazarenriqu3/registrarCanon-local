# Phase 6: Business Logic Improvements - Fee Settings Simplification

## Objective
Migrate from the legacy multi-table fee settings structure (`program_general_fees` and `program_specific_fees`) into a unified, wide-table JPA entity (`program_fee_settings`).

## Context & Rationale
Previously, the system split fee settings into:
1. `program_general_fees` (Core fees like Tuition and RLE rate)
2. `program_specific_fees` (EAV row-based table for Miscellaneous and Other fees)

This caused severe complexity in querying, requiring nested aggregations, fallback logic duplicated in raw JDBC strings, and a split source of truth.

**User Request**: Merge into one table structured by `program id \ term \ year \ semester` containing all the fee types as columns. If a fee is not required for the program, its value is 0.

## Implementation Details

### 1. Unified Entity Structure
We created `ProgramFeeSetting.java`, a JPA entity mapped to the `program_fee_settings` table. It includes:
- Scope columns: `programId`, `termId`, `yearLevel`, `semesterNumber`
- Core Fee columns: `feeTuitionPerUnit`, `feeLecPerUnit`, `feeLabPerUnit`, `feeCompPerUnit`, `feeRlePerUnit`
- Misc Fee columns: `feeMiscRegistration`, `feeMiscLibrary`, `feeMiscMedical`, `feeMiscId`, `feeMiscAthletic`
- Other Fee columns: `feeOtherLateEnrollment`, `feeOtherAddDrop`, `feeOtherInstallment`

### 2. Fallback Logic Simplification
We replaced the complex raw SQL chains with a clean Repository pattern in `ProgramFeeSettingRepository.java`:
```sql
SELECT * FROM program_fee_settings 
WHERE program_id = ?1 AND year_level = ?2 AND semester_number = ?3 AND is_active = 1 
AND (term_id = ?4 OR term_id IS NULL) 
ORDER BY CASE WHEN term_id = ?4 THEN 0 ELSE 1 END, fee_setting_id DESC LIMIT 1
```
This single query robustly handles Exact Term Match vs. Fallback (Term is NULL).

### 3. Service Refactoring
- **`TermFeeAdminService`**: Replaced ~800 lines of raw JDBC queries with Spring Data JPA. Simplified fee seeding, templating, and lookup operations.
- **`ScholarEnrollmentService`**: Removed raw JDBC queries reading from fee tables. Now properly injects `TermFeeAdminService` via constructor injection (adhering to Modulith boundaries) to lookup rates, improving testability and code reuse.

### 4. Backwards Compatibility
The `TermFeeAdminService` methods (`getFeeRatesForScope`, `listFeeTypesForAdmin`, etc.) were designed to map the unified JPA entity back to the generic `Map<String, Double>` structures expected by the existing `TermFeeAdminController`. This allowed us to overhaul the underlying persistence layer without modifying the HTTP/UI controller APIs.

## Testing & Verification
- Created `TermFeeAdminServiceTest` utilizing `@DataJpaTest` to verify that Fallback vs. Exact mappings behave correctly.
- Verified Modulith architectural boundaries and successfully passed `ModulithTests`.
- Successfully ran the entire regression suite, verifying that the new unified model seamlessly supports all existing business rules.

## Conclusion
The fee settings logic is now significantly more robust, type-safe, easier to read, and ready for future integrations (such as MCP).
