# Ultimate Execution & Testing Guide

This guide covers everything required to deploy the complete system schema (with the new Scholarships module), generate your massive test data, and test the tools/helpers accurately within your legacy structure.

## Step 1: Deploy the God Script
Because your PC likely had older, conflicting versions of the tables (like `class_schedules`), we must start fresh to guarantee success.

The script `db/archive/root-legacy/01_mega_schema_and_seed.sql` will now **DROP the entire `registrar_db_v2` database first**, recreate it perfectly clean via `COMPLETE_DATABASE_SETUP`, and loop-inject 1,000+ realistic students.

**Execution:**
1. Open MySQL Workbench.
2. Open `db/archive/root-legacy/01_mega_schema_and_seed.sql`.
3. Hit Execute (the Lightning Bolt icon).
4. After it finishes perfectly, trigger the test data loop:
   ```sql
   CALL seed_massive_integrated_data();
   ```

## Step 2: Load the Handlers
Run your two additional SQL scripts so the procedures are stored:
- Open & Execute **`02_tool_scripts.sql`** (Contains your applicant adders, manual scholarship grant checks, and test-data reset).
- Open & Execute **`02_admin_helpers.sql`** (Contains the internal scholarship Auto-Evaluator).

## Step 3: Run the Tests
Populate your MySQL console with these quick tests:

**1. Test Auto-Evalution (Internal Scholarships)**
Since your legacy `jp_grades` system tracks simple PASSED/FAILED statuses instead of numerical GWAs, the evaluator simply revokes scholarships from anyone who has a failed grade. Let's evaluate the generated data:
```sql
CALL evaluate_internal_scholarships();
```
*(Check the results by viewing your student_scholarships table!)*

**2. Test Manual Granting Blockers (External Scholarships)**
Remember, manual scholarships protect against giving money out to Applicants without official IDs:
```sql
-- Find an applicant's ID from sys_users and pass it here
-- Expected: ERROR 45000 (Requires officially generated ID) if user doesn't have an ID
CALL grant_manual_scholarship(55, 'Barangay Scholarship', 1);
```

**3. Cleanup the Slate safely**
When you want to reset your dummy test data but keep your real historical enrollment logs safe:
```sql
CALL reset_all_test_data();
```
