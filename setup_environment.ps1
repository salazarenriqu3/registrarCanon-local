<#
.SYNOPSIS
Sets up the Modulith Registrar Environment from scratch.

.DESCRIPTION
This script will:
1. Connect to MySQL and drop the existing eacdb database.
2. Recreate eacdb and load the purified schema (00_MASTER_SETUP_CLEAN.sql).
3. Load the demo personas and curriculum data (01_MASTER_DEMO_DATA.sql).
4. Run a clean Maven build of the Spring Boot application.

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
Write-Host "🚀 INITIALIZING DATABASE ENVIRONMENT 🚀"
Write-Host "========================================"

Write-Host "Dropping and recreating 'eacdb'..."
& $MySqlPath -u root --password= -e "DROP DATABASE IF EXISTS eacdb; CREATE DATABASE eacdb;"

Write-Host "Loading purified schema and lookup data (00_MASTER_SETUP_CLEAN.sql)..."
Get-Content "db\setup\00_MASTER_SETUP_CLEAN.sql" | & $MySqlPath -u root --password= eacdb

Write-Host "Loading demo personas and curriculum (01_MASTER_DEMO_DATA.sql)..."
Get-Content "db\setup\01_MASTER_DEMO_DATA.sql" | & $MySqlPath -u root --password= eacdb

Write-Host ""
Write-Host "========================================"
Write-Host "📦 BUILDING SPRING MODULITH APP 📦"
Write-Host "========================================"
mvn clean install -DskipTests

Write-Host ""
Write-Host "✅ Setup Complete! You can now start the application using:"
Write-Host "   mvn spring-boot:run"
Write-Host ""
