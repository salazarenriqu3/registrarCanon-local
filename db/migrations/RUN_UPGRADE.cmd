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

echo === Sprint 1-10 schema upgrade (non-destructive) ===
echo Database: %DB_USER%@%DB_HOST%/eacdb
echo.

"%MYSQL_EXE%" -h "%DB_HOST%" -u "%DB_USER%" eacdb < "%~dp020260619_sprint_1_10_upgrade.sql"
if errorlevel 1 (
  echo FAILED: migration script
  exit /b 1
)

echo.
echo SUCCESS. Run verification:
echo   mysql -u %DB_USER% eacdb ^< registrar\db\sql_manual\12_verify_sprint_features.sql
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
