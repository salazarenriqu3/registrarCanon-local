# Minimal bootstrap for MANUAL configuration track
# OPTIONAL SHORTCUT — same SQL as FRESH_PC_COMPLETE_DEMO_MANUAL.md Part 2M steps 1-3
# Preferred: run SQL files directly in Workbench (see sql_manual/README.md)
# Usage: powershell -ExecutionPolicy Bypass -File setup_fresh_pc_minimal.ps1

$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root
$RunSqlPy = Join-Path $Root "_runtime_logs\run_sql_file.py"

function Run-SqlFile($relativePath) {
    $path = Join-Path $Root $relativePath
    Write-Host "`n=== $relativePath ===" -ForegroundColor Cyan
    python $RunSqlPy $path
    if ($LASTEXITCODE -ne 0) { throw "Failed: $relativePath" }
}

Write-Host "MANUAL TRACK - minimal bootstrap" -ForegroundColor Green
Write-Host "Project root: $Root"

Run-SqlFile "registrar\db\fix"
Run-SqlFile "registrar\db\sql_manual\01_calendar_and_active_term.sql"
Run-SqlFile "registrar\db\sql_manual\06_retire_empty_programs.sql"

Write-Host "`n=== NEXT: manual configuration ===" -ForegroundColor Yellow
Write-Host '  1. Start Registrar + Enrollment (MASTER_DEMO_UAT_MANUAL.md Part 4)'
Write-Host '  2. Follow Part 2M + Part 5M in that manual'
Write-Host '  3. python _runtime_logs/run_full_preflight.py when ready'
Write-Host 'Manual: registrar/docs/handoff/MASTER_DEMO_UAT_MANUAL.md'
