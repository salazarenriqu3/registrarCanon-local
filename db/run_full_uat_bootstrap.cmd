@echo off
REM Legacy path — forwards to registrar\setup\RUN_FRESH_SETUP.cmd
cd /d "%~dp0\..\setup"
call RUN_FRESH_SETUP.cmd
