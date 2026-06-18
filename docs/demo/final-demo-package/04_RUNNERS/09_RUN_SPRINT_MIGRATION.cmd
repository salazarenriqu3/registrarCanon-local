@echo off
setlocal EnableExtensions

set "WORKSPACE_ROOT=%~dp0..\..\..\.."
for %%I in ("%WORKSPACE_ROOT%") do set "WORKSPACE_ROOT=%%~fI"

echo === Non-destructive Sprint 1-10 schema upgrade ===
call "%WORKSPACE_ROOT%\db\migrations\RUN_UPGRADE.cmd"
exit /b %ERRORLEVEL%
