@echo off
REM Prerequisite checker — run from project root or anywhere.
cd /d "%~dp0\..\.."
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0CHECK_PREREQUISITES.ps1" -ProjectRoot "%CD%"
exit /b %ERRORLEVEL%
