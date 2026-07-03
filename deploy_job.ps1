$ErrorActionPreference = "Stop"
$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
$appSettingsPath = Join-Path (Split-Path $scriptDir -Parent) "backend-ai\appsettings.Development.json"

Write-Host "Reading connection string from: $appSettingsPath"
$json = Get-Content -Raw -Path $appSettingsPath | ConvertFrom-Json
$ConnectionString = $json.ConnectionStrings.defaultConnectionbeta

$file = Join-Path $scriptDir "Jobs\Create_Daily_Update_VendorViseKycStatus_DeleteMark_Job.sql"
Write-Host "Deploying Job from: $file"

Add-Type -AssemblyName System.Data
$conn = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
$conn.Open()

try {
    $sqlContent = Get-Content -Raw -Path $file
    $batches = [regex]::Split($sqlContent, '(?mi)^\s*GO\s*$')
    
    foreach ($batch in $batches) {
        if ([string]::IsNullOrWhiteSpace($batch)) { continue }
        
        $cmd = $conn.CreateCommand()
        $cmd.CommandText = $batch
        $cmd.CommandTimeout = 120
        $cmd.ExecuteNonQuery() > $null
    }
    Write-Host "Job deployed successfully!" -ForegroundColor Green
} catch {
    Write-Host "Error deploying job: $_" -ForegroundColor Red
    exit 1
} finally {
    $conn.Close()
}
