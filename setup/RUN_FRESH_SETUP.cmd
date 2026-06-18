@echo off

REM ============================================================================

REM  EAC Fresh Setup — one command, SQL only, no Python

REM  Active term after run: 1120242025 (A.Y. 2024-25, 1st Semester)

REM

REM  From project root:

REM    registrar\setup\CHECK_PREREQUISITES.cmd   (optional but recommended)

REM    registrar\setup\RUN_FRESH_SETUP.cmd

REM

REM  Agent playbook: registrar\setup\AGENT_FRESH_SETUP.md

REM ============================================================================



setlocal EnableExtensions

cd /d "%~dp0\..\.."



if /I not "%~1"=="--skip-prereq" (

  echo.

  echo === PREREQUISITE CHECK ===

  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0CHECK_PREREQUISITES.ps1" -ProjectRoot "%CD%"

  if errorlevel 1 (

    echo.

    echo STOP: Fix prerequisites first. See registrar\setup\AGENT_FRESH_SETUP.md

    pause

    exit /b 1

  )

  echo.

)



call :find_mysql

if errorlevel 1 (

  echo.

  echo FAILED: mysql.exe not found.

  pause

  exit /b 1

)



echo.

echo === EAC FRESH SETUP ===

echo Project root: %CD%

echo MySQL:        %MYSQL_EXE%

echo Active term:  1120242025 (2425 1st sem)

echo Manifest:     registrar\setup\BOOTSTRAP_SEED_MANIFEST.md

echo.



echo --- DROP + CREATE eacdb ---

"%MYSQL_EXE%" -u root -e "DROP DATABASE IF EXISTS eacdb; CREATE DATABASE eacdb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

if errorlevel 1 (

  echo FAILED: could not recreate eacdb. Is MariaDB running?

  pause

  exit /b 1

)



echo.

echo === Core schema + seeds (19 steps — see BOOTSTRAP_SEED_MANIFEST.md) ===



call :run "registrar\db\fix"

call :run "enrollment3\src\main\resources\sql\01_enlistment_status_schema.sql"

call :run "registrar\db\04_seed_full_curriculum.sql"

call :run "registrar\db\demo_scripts\00_upsert_academic_terms_calendar.sql"

call :run "registrar\db\capss-demo-required\01_setup\03_seed_program_fees_full_lifecycle.sql"

call :run "registrar\docs\business_logic\schema_migration_001.sql"

call :run "registrar\db\manual_patches\20260608_retire_empty_curriculum_blockers.sql"

call :run "registrar\db\seed_all_program_block_sections_calendar.sql"

call :run "registrar\db\seed_block_offerings.sql"

call :run "registrar\db\seed_irregular_open_sections.sql"

call :run "registrar\db\seed_faculty_professors_and_grading.sql"

call :run "registrar\db\seed_all_class_schedules.sql"

call :run "registrar\setup\sql\01_activate_term_2425_s1.sql"

call :run "registrar\setup\sql\02_materialize_term_fees.sql"

call :run "registrar\setup\sql\05_materialize_all_calendar_term_fees.sql"

call :run "registrar\setup\sql\03_assign_prof_cruz_demo.sql"

call :run "registrar\setup\sql\04_verify_readiness.sql"

call :run "registrar\db\migrations\20260619_sprint_1_10_upgrade.sql"

call :run "registrar\db\demo_scripts\19_sprint_features_demo_seed.sql"



echo.

echo === DONE ===

echo.

echo Next steps:

echo   1. Start Registrar:  cd registrar ^&^& mvn -q spring-boot:run

echo   2. Start Enrollment: cd enrollment3 ^&^& mvn -q spring-boot:run

echo   3. UI smoke: registrar\docs\handoff\HUMAN_UAT_CHECKLIST.md Session 0

echo   4. Agent doc:  registrar\setup\AGENT_FRESH_SETUP.md

echo.

pause

exit /b 0



:find_mysql

set "MYSQL_EXE="

where mysql >nul 2>&1 && set "MYSQL_EXE=mysql"

if defined MYSQL_EXE exit /b 0

for /d %%D in ("C:\Program Files\MariaDB*") do (

  if exist "%%D\bin\mysql.exe" set "MYSQL_EXE=%%D\bin\mysql.exe"

)

if defined MYSQL_EXE exit /b 0

for /d %%D in ("C:\Program Files\MySQL\MySQL Server*") do (

  if exist "%%D\bin\mysql.exe" set "MYSQL_EXE=%%D\bin\mysql.exe"

)

if defined MYSQL_EXE exit /b 0

exit /b 1



:run

echo --- %~1 ---

"%MYSQL_EXE%" -u root eacdb < "%~1"

if errorlevel 1 (

  echo FAILED: %~1

  pause

  exit /b 1

)

goto :eof

