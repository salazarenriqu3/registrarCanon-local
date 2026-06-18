@echo off
setlocal EnableExtensions
cd /d "%~dp0\..\.."

set "DB_HOST=%EAC_DB_HOST%"
if not defined DB_HOST set "DB_HOST=127.0.0.1"
set "DB_USER=%EAC_DB_USER%"
if not defined DB_USER set "DB_USER=root"
if defined EAC_DB_PASSWORD set "MYSQL_PWD=%EAC_DB_PASSWORD%"

call :find_mysql
if errorlevel 1 (
  echo FAILED: mysql.exe not found.
  exit /b 1
)

echo === Storyboard demo prep (MySQL) ===
"%MYSQL_EXE%" -h "%DB_HOST%" -u "%DB_USER%" eacdb < "%~dp0STORYBOARD_SQL_ALL_IN_ONE.sql"
if errorlevel 1 exit /b 1

echo.
echo Optional: load withdrawal UAT student
set "WDRW="
set /p "WDRW=Load WDRW-UAT-2026-001 withdrawal seed? [y/N]: "
if /I "%WDRW%"=="y" (
  "%MYSQL_EXE%" -h "%DB_HOST%" -u "%DB_USER%" eacdb < "%~dp016_withdrawal_uat_seed.sql"
)

echo.
echo SUCCESS. Open docs/handoff/PRESENTATION_STORYBOARD.md and start Act 1.
exit /b 0

:find_mysql
set "MYSQL_EXE="
where mysql >nul 2>&1 && set "MYSQL_EXE=mysql"
if defined MYSQL_EXE exit /b 0
for /d %%D in ("C:\Program Files\MariaDB*") do if exist "%%D\bin\mysql.exe" set "MYSQL_EXE=%%D\bin\mysql.exe"
if defined MYSQL_EXE exit /b 0
for /d %%D in ("C:\Program Files\MySQL\MySQL Server*") do if exist "%%D\bin\mysql.exe" set "MYSQL_EXE=%%D\bin\mysql.exe"
if defined MYSQL_EXE exit /b 0
exit /b 1
