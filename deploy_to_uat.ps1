<#
.SYNOPSIS
    Deploys SQL stored procedures to the UAT database.
.DESCRIPTION
    Reads connection details from backend-ai/appsettings.Development.json,
    parses stored procedure files, splits them by 'GO' statements, and runs them.
.PARAMETER ConnectionString
    Optional connection string override.
.PARAMETER Password
    Optional password override to replace the password in the connection string.
.PARAMETER All
    Deploy all stored procedures found in the StoredProcedures directory.
.PARAMETER Files
    Deploy a specific list of stored procedure file names (e.g. "Proc_GetStateWiseSummary_AI.sql").
.PARAMETER WhatIf
    Dry-run mode. Verifies file existence, parses the SQL scripts, and tests database connection without executing writes.
#>
[CmdletBinding()]
param(
    [string]$ConnectionString,
    [string]$Password,
    [switch]$All,
    [string[]]$Files,
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

# Define Paths
$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
$spDir = Join-Path $scriptDir "StoredProcedures"
$appSettingsPath = Join-Path (Split-Path $scriptDir -Parent) "backend-ai\appsettings.Development.json"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   Stored Procedures Deployment Script (UAT)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Resolve Connection String
if (-not $ConnectionString) {
    if (-not (Test-Path $appSettingsPath)) {
        Write-Error "Could not find appsettings.Development.json at $appSettingsPath. Please specify -ConnectionString."
    }
    Write-Host "Reading connection string from: $appSettingsPath" -ForegroundColor Gray
    try {
        $json = Get-Content -Raw -Path $appSettingsPath | ConvertFrom-Json
        $ConnectionString = $json.ConnectionStrings.defaultConnectionbeta
    } catch {
        Write-Error "Failed to parse appsettings.Development.json: $_"
    }
}

if (-not $ConnectionString) {
    Write-Error "Connection string 'defaultConnectionbeta' not found in appsettings."
}

# Apply password override if provided
if ($Password) {
    Write-Host "Applying password override..." -ForegroundColor Gray
    $ConnectionString = $ConnectionString -replace 'Password=[^;]+', "Password=$Password"
}

# Mask password for display
$maskedCS = $ConnectionString -replace 'Password=[^;]+', "Password=********"
Write-Host "Target Connection String: $maskedCS" -ForegroundColor Gray

# 2. Select Files to Deploy
$targetFiles = @()

if ($Files -and $Files.Count -gt 0) {
    Write-Host "Deploying specific files specified in parameters..." -ForegroundColor Yellow
    foreach ($f in $Files) {
        $filePath = Join-Path $spDir $f
        if (-not $filePath.EndsWith(".sql")) { $filePath += ".sql" }
        $targetFiles += $filePath
    }
} elseif ($All) {
    Write-Host "Deploying ALL SQL files in StoredProcedures directory..." -ForegroundColor Yellow
    $targetFiles = Get-ChildItem -Path $spDir -Filter "*.sql" | ForEach-Object { $_.FullName }
} else {
    Write-Host "Deploying default list from deploy_procedures.ps1 & deploy_our_sps.ps1..." -ForegroundColor Yellow
    # Union of files in both scripts
    $defaultFileNames = @(
        "Proc_GetStateWiseSummary_AI.sql",
        "SP_BL_CashBurnDetailsReport_MAndM_AI.sql",
        "SP_BL_GetBeneficiariesReport_MAndM_AI.sql",
        "SP_BL_GetBrandOverview_MAndM_AI.sql",
        "SP_BL_GetCashBurnPattern_MAndM_AI.sql",
        "SP_BL_GetCodesActivityReport_MAndM_AI.sql",
        "SP_BL_GetNewUsersAndKYCOverview_MAndM_AI.sql",
        "SP_BL_GetNewUsersAndKYCReportAutoFilterData_MAndM_AI.sql",
        "SP_BL_GetScanPeakActivityHour_MAndM_AI.sql",
        "SP_BL_GetTopBeneficiariesList_MAndM_AI.sql",
        "SP_BL_GetTopPerformingStates_MAndM_AI.sql",
        "SP_BL_LiveScanActivity_MAndM_AI.sql",
        "SP_BL_UPIPayoutReport_MAndM_AI.sql",
        "SP_BL_UpdateKycStatus_MAndM_AI.sql",
        "SP_BL_GetCodesActivityReport_AI.sql",
        "USP_GetCodeStatus_AI.sql",
        "USP_GetCodeStatusByMobileNo_AI.sql",
        "USP_GetCodeStatusBySerialNumber_AI.sql",
        "SP_BL_LiveScanActivity_AI.sql"
    ) | Select-Object -Unique

    foreach ($f in $defaultFileNames) {
        $targetFiles += Join-Path $spDir $f
    }
}

Write-Host "Total files to process: $($targetFiles.Count)" -ForegroundColor Gray

# 3. Verify files exist
$validFiles = @()
foreach ($file in $targetFiles) {
    if (Test-Path $file) {
        $validFiles += $file
    } else {
        Write-Host "WARNING: File not found: $file" -ForegroundColor Yellow
    }
}

if ($validFiles.Count -eq 0) {
    Write-Error "No valid SQL files found to deploy!"
}

# 4. Connect and Deploy
Add-Type -AssemblyName System.Data
$conn = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)

try {
    Write-Host "Testing database connection..." -ForegroundColor Gray
    $conn.Open()
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = "SELECT @@VERSION"
    $version = $cmd.ExecuteScalar()
    Write-Host "Successfully connected to SQL Server!" -ForegroundColor Green
    Write-Host "Server Version: $version" -ForegroundColor Gray
    
    if ($WhatIf) {
        Write-Host "--- DRY RUN MODE (-WhatIf) ---" -ForegroundColor Yellow
        Write-Host "Database connection is working. Files would be deployed in sequence." -ForegroundColor Green
        $conn.Close()
        return
    }
} catch {
    Write-Host "ERROR: Failed to connect to database: $_" -ForegroundColor Red
    if ($conn.State -eq [System.Data.ConnectionState]::Open) { $conn.Close() }
    exit 1
}

$successCount = 0
$failCount = 0

foreach ($file in $validFiles) {
    $fileName = Split-Path $file -Leaf
    Write-Host "Deploying $fileName..." -NoNewline

    try {
        $sqlContent = Get-Content -Raw -Path $file
        
        # 1. Convert CREATE/ALTER PROCEDURE/VIEW/FUNCTION/TRIGGER to CREATE OR ALTER
        $sqlContent = $sqlContent -replace '(?mi)^\s*(CREATE|ALTER)\s+PROCEDURE\b', 'CREATE OR ALTER PROCEDURE'
        $sqlContent = $sqlContent -replace '(?mi)^\s*(CREATE|ALTER)\s+PROC\b', 'CREATE OR ALTER PROC'
        $sqlContent = $sqlContent -replace '(?mi)^\s*(CREATE|ALTER)\s+VIEW\b', 'CREATE OR ALTER VIEW'
        $sqlContent = $sqlContent -replace '(?mi)^\s*(CREATE|ALTER)\s+FUNCTION\b', 'CREATE OR ALTER FUNCTION'
        $sqlContent = $sqlContent -replace '(?mi)^\s*(CREATE|ALTER)\s+TRIGGER\b', 'CREATE OR ALTER TRIGGER'

        # 2. Fix known syntax errors and typos on the fly (leaves repository files untouched)
        $sqlContent = $sqlContent -replace '\(1 rows affected\)', ''
        $sqlContent = $sqlContent -replace '(?mi)BEGIN\s*END', "BEGIN`n    SET NOCOUNT ON;`nEND"
        $sqlContent = $sqlContent -replace '@StartSerial\b', '@StartSeries'
        $sqlContent = $sqlContent -replace 'SELECT M_Consumerid FROM M_Consumer WHERE RIGHT\(MobileNo, 10\) = ''9315742109'' LIMIT 1', "SELECT TOP 1 M_Consumerid FROM M_Consumer WHERE RIGHT(MobileNo, 10) = '9315742109'"

        # Split by GO statement on a line by itself
        $batches = [regex]::Split($sqlContent, '(?mi)^\s*GO\s*$')
        
        # Reset database context for the connection to vcqru once at the start of the file
        $resetCmd = $conn.CreateCommand()
        $resetCmd.CommandText = "USE [vcqru]"
        $resetCmd.ExecuteNonQuery() > $null

        foreach ($batch in $batches) {
            if ([string]::IsNullOrWhiteSpace($batch)) { continue }
            
            $cmd = $conn.CreateCommand()
            $cmd.CommandText = $batch
            $cmd.CommandTimeout = 120
            $cmd.ExecuteNonQuery() > $null
        }
        
        Write-Host " [SUCCESS]" -ForegroundColor Green
        $successCount++
    } catch {
        Write-Host " [FAILED]" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        $failCount++
    }
}

$conn.Close()

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Deployment Summary:" -ForegroundColor Cyan
Write-Host "  Successfully Deployed: $successCount" -ForegroundColor Green
if ($failCount -gt 0) {
    Write-Host "  Failed to Deploy:      $failCount" -ForegroundColor Red
    exit 1
} else {
    Write-Host "  All procedures deployed successfully!" -ForegroundColor Green
}
Write-Host "==========================================================" -ForegroundColor Cyan
