# DEPRECATED — 2026-06-09
# This script uses an incomplete bootstrap chain (missing enlistment schema,
# schema_migration_001, 11_bootstrap_materialize, verify).
#
# USE INSTEAD (SQL only, no Python):
#   registrar\db\run_full_uat_bootstrap.cmd
#
# Or read: registrar/handoffNew/START_HERE_NEW_PC_HANDOFF.md
#          registrar/handoffNew/HANDOFF_UPDATES_20260609.md

Write-Host "DEPRECATED: setup_fresh_pc.ps1" -ForegroundColor Yellow
Write-Host ""
Write-Host "Run from project root (the 'new' folder):" -ForegroundColor Cyan
Write-Host "  registrar\db\run_full_uat_bootstrap.cmd" -ForegroundColor Green
Write-Host ""
Write-Host "See: registrar/handoffNew/START_HERE_NEW_PC_HANDOFF.md" -ForegroundColor Gray
exit 1
