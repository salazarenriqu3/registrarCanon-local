<#
.SYNOPSIS
Sets up and runs the Full Legacy Registrar Environment (Scenario B).

.DESCRIPTION
This script will:
1. Connect to MySQL and drop the existing eacdb database.
2. Recreate eacdb and load the schema (01_SCHEMA_CLEAN.sql).
3. Load the curriculums, programs, and personnel (02_DEMO_DATA.sql).
4. Load the term fee and admissions test data (03_TEST_DATA_FEES.sql).
5. Start the Spring Boot application using the eacdb database.

.NOTES
Make sure MySQL is running on localhost:3306 and the root user has no password (or edit this script).
#>

$ErrorActionPreference = "Stop"

$MySqlPath = "C:\Program Files\MySQL\MySQL Workbench 8.0 CE\mysql.exe"
if (-not (Test-Path $MySqlPath)) {
    Write-Host "MySQL Workbench not found at default path. Checking Server 8.0 path..."
    $MySqlPath = "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"
    if (-not (Test-Path $MySqlPath)) {
        Write-Error "Could not find mysql.exe. Please add it to your PATH or update this script."
        exit
    }
}

Write-Host "========================================"
Write-Host "🚀 INITIALIZING FULL ENVIRONMENT 🚀"
Write-Host "========================================"

Write-Host "Dropping and recreating 'eacdb'..."
& $MySqlPath -u root --password= -e "DROP DATABASE IF EXISTS eacdb; CREATE DATABASE eacdb;"

Write-Host "Loading full schema (01_SCHEMA_CLEAN.sql)..."
Get-Content "01_SCHEMA_CLEAN.sql" | & $MySqlPath -u root --password= eacdb

Write-Host "Loading curriculums and personas (02_DEMO_DATA.sql)..."
Get-Content "02_DEMO_DATA.sql" | & $MySqlPath -u root --password= eacdb

Write-Host "Loading term fee test scenarios (03_TEST_DATA_FEES.sql)..."
Get-Content "03_TEST_DATA_FEES.sql" | & $MySqlPath -u root --password= eacdb

Write-Host ""
Write-Host "========================================"
Write-Host "📦 RUNNING SPRING BOOT 📦"
Write-Host "========================================"
# The app defaults to eacdb, so we just run it:
cd ..
mvn spring-boot:run
