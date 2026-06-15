# Curriculum Seeding Rules

## Purpose

This note defines the safe curriculum build/seed logic now implemented in registrar.

## Business Rules

- `program_code` is a business-owned offering id and must never be guessed from a filename.
- A curriculum is versioned per program in `curriculum_templates`.
- A student should resolve to a specific curriculum version, not just a program.
- A program is only curriculum-ready when its active curriculum has real `curriculum_courses` rows.
- Placeholder curricula may exist for blocked programs, but they are not operational curricula.

## Seed Sources

Registrar now uses the explicit manifest at:

- `src/main/resources/curriculum/curriculum-seed-manifest.csv`

Each active program is classified as:

- `DIRECT`: publish from its approved source file into that same program code
- `SHARED`: publish shared source content into a different, still-active program code without deactivating either code
- `BLOCKED`: no approved source file yet; readiness may use a placeholder template for visibility only

## Runtime Behavior

- `Seed All from Manifest` only processes manifest-approved targets.
- The seed path no longer creates or renames programs from `.docx` filenames.
- Existing operational curricula are skipped instead of being overwritten.
- Missing-program repairs no longer deactivate alias-like offerings during readiness repair.
- `Repair Readiness` only creates placeholders for manifest-blocked programs.

## Student Safety

- Default curriculum assignment now requires an active curriculum that also has course rows.
- Empty active templates no longer count as curriculum-ready in term readiness.
- Enrollment regular-block UI should only offer section-group buttons when real active-term block `class_sections` exist for `PROGRAM-YEAR-SEM-GROUP`.
- BSCPE year `1`, semester `1` active-term block sections were seeded from the real BSCPE curriculum for hard testing.

## Next Runtime Step

When ready to populate live curricula:

1. Run `Seed All from Manifest`
2. Run `Repair Readiness`
3. Recheck System Settings / term readiness
4. Review which programs remain blocked because they still lack approved source curricula
