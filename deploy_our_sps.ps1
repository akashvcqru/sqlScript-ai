$files = @(
    "SP_BL_GetCodesActivityReport_AI.sql",
    "SP_BL_GetCodesActivityReport_MAndM_AI.sql",
    "USP_GetCodeStatus_AI.sql",
    "USP_GetCodeStatusByMobileNo_AI.sql",
    "USP_GetCodeStatusBySerialNumber_AI.sql",
    "SP_BL_LiveScanActivity_AI.sql",
    "SP_BL_LiveScanActivity_MAndM_AI.sql",
    "USP_ReassignCodesBulkUpload_AI.sql"
)

$dir = "c:\VCQRU-Project\sqlScript\StoredProcedures"

foreach ($file in $files) {
    $filePath = Join-Path $dir $file
    if (Test-Path $filePath) {
        Write-Host "Deploying $file..."
        & sqlcmd -S '20.204.114.42\ProdAdmin,1433' -d vcqru -U sa -P 'VWRYE34@#!$@ESfgd' -i $filePath
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Successfully deployed $file" -ForegroundColor Green
        } else {
            Write-Host "Error deploying $file" -ForegroundColor Red
        }
    } else {
        Write-Host "File not found: $filePath" -ForegroundColor Yellow
    }
}
