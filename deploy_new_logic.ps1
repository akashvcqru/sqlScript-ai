$connectionString = "Connect Timeout=100000;pooling=true;Max Pool Size=200;Data Source=20.204.114.42\ProdAdmin,1433;Initial Catalog=vcqru;User ID=sa;Password=VWRYE34@#!$@ESfgd;TrustServerCertificate=True"
$dllPath = "c:\VCQRU-Project\backend-ai\bin\Debug\net10.0\Microsoft.Data.SqlClient.dll"
$sqlFiles = @(
    "c:\VCQRU-Project\sqlScript-ai\StoredProcedures\USP_GenerateAndSaveCodes_Unified.sql",
    "c:\VCQRU-Project\sqlScript-ai\StoredProcedures\USP_GetCodeGenerationReport.sql"
)

# Load the SQL Client assembly
Add-Type -Path $dllPath

foreach ($sqlFilePath in $sqlFiles) {
    if (-not (Test-Path $sqlFilePath)) {
        Write-Error "SQL file not found at $sqlFilePath"
        continue
    }

    $sqlContent = Get-Content -Path $sqlFilePath -Raw
    # Split the SQL script by 'GO'
    $statements = [System.Text.RegularExpressions.Regex]::Split($sqlContent, "^\s*GO\s*$", [System.Text.RegularExpressions.RegexOptions]::Multiline -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

    try {
        $connection = New-Object Microsoft.Data.SqlClient.SqlConnection($connectionString)
        $connection.Open()
        Write-Host "Connected to database for file: $sqlFilePath"

        foreach ($statement in $statements) {
            if (-not [string]::IsNullOrWhiteSpace($statement)) {
                $command = $connection.CreateCommand()
                $command.CommandText = $statement.Trim()
                $command.ExecuteNonQuery() | Out-Null
                Write-Host "Executed statement in $sqlFilePath"
            }
        }
        Write-Host "Script $sqlFilePath executed successfully."
    }
    catch {
        Write-Error "Failed to execute SQL for ${sqlFilePath}: $_"
    }
    finally {
        if ($null -ne $connection) {
            $connection.Close()
        }
    }
}
