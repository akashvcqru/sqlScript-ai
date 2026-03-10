$connectionString = "Connect Timeout=100000;pooling=true;Max Pool Size=200;Data Source=20.204.114.42\ProdAdmin,1433;Initial Catalog=vcqru;User ID=sa;Password=VWRYE34@#!$@ESfgd;TrustServerCertificate=True"
$sqlFilePath = "c:\VCQRU-Project\sqlScript-ai\StoredProcedures\USP_GetCompanyLoginDetails.sql"
$dllPath = "c:\VCQRU-Project\backend-ai\bin\Debug\net10.0\Microsoft.Data.SqlClient.dll"

# Load the SQL Client assembly
Add-Type -Path $dllPath

if (-not (Test-Path $sqlFilePath)) {
    Write-Error "SQL file not found at $sqlFilePath"
    exit 1
}

$sqlContent = Get-Content -Path $sqlFilePath -Raw

# Split the SQL script by 'GO' (on its own line, case-insensitive)
$statements = [System.Text.RegularExpressions.Regex]::Split($sqlContent, "^\s*GO\s*$", [System.Text.RegularExpressions.RegexOptions]::Multiline -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

try {
    $connection = New-Object Microsoft.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    Write-Host "Connected to database."

    foreach ($statement in $statements) {
        if (-not [string]::IsNullOrWhiteSpace($statement)) {
            $command = $connection.CreateCommand()
            $command.CommandText = $statement.Trim()
            $command.ExecuteNonQuery() | Out-Null
            Write-Host "Executed statement."
        }
    }

    Write-Host "Stored procedure created successfully."
}
catch {
    Write-Error "Failed to execute SQL: $_"
    exit 1
}
finally {
    if ($null -ne $connection) {
        $connection.Close()
    }
}
