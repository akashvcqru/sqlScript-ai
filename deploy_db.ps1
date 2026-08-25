param (
    [string]$TargetEnv = "UAT"
)

$ErrorActionPreference = "Stop"
$scriptDir = $PSScriptRoot

# 1. Retrieve connection string from Environment Variables (set by GitHub Actions or local env)
$connectionString = $env:DB_CONNECTION_STRING

if (-not $connectionString) {
    Write-Error "Error: DB_CONNECTION_STRING environment variable is not set!"
}

# Add SQL client support
Add-Type -AssemblyName System.Data
$conn = New-Object System.Data.SqlClient.SqlConnection($connectionString)

Write-Host "Connecting to SQL Server for environment: $TargetEnv..."
try {
    $conn.Open()
    Write-Host "Connection Successful!" -ForegroundColor Green
} catch {
    Write-Error "Failed to connect to database: $_"
}

# -------------------------------------------------------------
# STEP 1: RUN MIGRATIONS (if any new ones exist)
# -------------------------------------------------------------
$migrationsDir = Join-Path $scriptDir "Migrations"
if (Test-Path $migrationsDir) {
    Write-Host "Checking for database migrations..." -ForegroundColor Cyan
    $migrationFiles = Get-ChildItem -Path $migrationsDir -Filter "*.sql" | Sort-Object Name

    foreach ($file in $migrationFiles) {
        # Check if we should skip .gitkeep or other non-migration files
        if ($file.Name -eq ".gitkeep") { continue }
        
        Write-Host "Running migration: $($file.Name)..." -NoNewline
        try {
            $sqlContent = Get-Content -Raw -Path $file.FullName
            $batches = [regex]::Split($sqlContent, '(?mi)^\s*GO\s*$')
            
            foreach ($batch in $batches) {
                if ([string]::IsNullOrWhiteSpace($batch)) { continue }
                $cmd = $conn.CreateCommand()
                $cmd.CommandText = $batch
                $cmd.CommandTimeout = 0
                $cmd.ExecuteNonQuery() > $null
            }
            Write-Host " [SUCCESS]" -ForegroundColor Green
        } catch {
            Write-Host " [FAILED]" -ForegroundColor Red
            Write-Error "Migration error in $($file.Name): $_"
        }
    }
}

# -------------------------------------------------------------
# STEP 2: DEPLOY STORED PROCEDURES
# -------------------------------------------------------------
$spDir = Join-Path $scriptDir "StoredProcedures"
if (Test-Path $spDir) {
    Write-Host "Deploying Stored Procedures..." -ForegroundColor Cyan
    $spFiles = Get-ChildItem -Path $spDir -Filter "*.sql"

    foreach ($file in $spFiles) {
        # Skip full DB dump files
        if ($file.Name -eq "SQLQuery_Script.sql") { continue }

        Write-Host "Deploying SP: $($file.Name)..." -NoNewline
        try {
            $sqlContent = Get-Content -Raw -Path $file.FullName
            
            # Convert CREATE to CREATE OR ALTER dynamically
            $sqlContent = $sqlContent -replace '(?mi)^\s*(CREATE|ALTER)\s+PROCEDURE\b', 'CREATE OR ALTER PROCEDURE'
            $sqlContent = $sqlContent -replace '(?mi)^\s*(CREATE|ALTER)\s+PROC\b', 'CREATE OR ALTER PROC'
            $sqlContent = $sqlContent -replace '(?mi)^\s*(CREATE|ALTER)\s+VIEW\b', 'CREATE OR ALTER VIEW'
            $sqlContent = $sqlContent -replace '(?mi)^\s*(CREATE|ALTER)\s+FUNCTION\b', 'CREATE OR ALTER FUNCTION'

            $batches = [regex]::Split($sqlContent, '(?mi)^\s*GO\s*$')
            
            foreach ($batch in $batches) {
                if ([string]::IsNullOrWhiteSpace($batch)) { continue }
                $cmd = $conn.CreateCommand()
                $cmd.CommandText = $batch
                $cmd.CommandTimeout = 0
                $cmd.ExecuteNonQuery() > $null
            }
            Write-Host " [SUCCESS]" -ForegroundColor Green
        } catch {
            Write-Host " [FAILED]" -ForegroundColor Red
            Write-Warning "Error deploying SP $($file.Name): $_"
        }
    }
}

$conn.Close()
Write-Host "Deployment Completed Successfully for $TargetEnv!" -ForegroundColor Green
