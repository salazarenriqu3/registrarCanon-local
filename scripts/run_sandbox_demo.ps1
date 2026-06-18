<#
.SYNOPSIS
Sets up and runs the isolated Registrar Sandbox Environment.

.DESCRIPTION
This script will:
1. Connect to MySQL and drop the existing registrar_sandbox database.
2. Recreate registrar_sandbox and load the handcrafted schema (01_MANUAL_SCHEMA_CORE.sql).
3. Load the pure seed test data (02_MANUAL_SEED_TEST_DATA.sql).
4. Start the Spring Boot application using the sandbox datasource.

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
Write-Host "🚀 INITIALIZING SANDBOX ENVIRONMENT 🚀"
Write-Host "========================================"

Write-Host "Dropping and recreating 'registrar_sandbox'..."
& $MySqlPath -u root --password= -e "DROP DATABASE IF EXISTS registrar_sandbox; CREATE DATABASE registrar_sandbox;"

Write-Host "Loading pure schema (01_MANUAL_SCHEMA_CORE.sql)..."
Get-Content "db\manual_tests\01_MANUAL_SCHEMA_CORE.sql" | & $MySqlPath -u root --password= registrar_sandbox

Write-Host "Loading seed data (02_MANUAL_SEED_TEST_DATA.sql)..."
Get-Content "db\manual_tests\02_MANUAL_SEED_TEST_DATA.sql" | & $MySqlPath -u root --password= registrar_sandbox

Write-Host ""
Write-Host "========================================"
Write-Host "📦 RUNNING SPRING BOOT ON SANDBOX 📦"
Write-Host "========================================"
$env:SPRING_DATASOURCE_URL="jdbc:mysql://127.0.0.1:3306/registrar_sandbox?serverTimezone=Asia/Manila"
mvn spring-boot:run
