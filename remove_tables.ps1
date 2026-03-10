$tablesToRemove = @(
    "M_Consumer_241225",
    "M_ConsumerBK031225",
    "m_dealermaster261225",
    "m_dealermaster_mahindra_emp_030226",
    "m_dealermaster_mahindra_empbk_05012026",
    "PFL_Batchlist_230725",
    "PFL_Batchlist210126",
    "PFL_Batchlist260226",
    "pfl_Batchlist_temp_260226",
    "Remarks5",
    "Remarks1",
    "tbl_event_bk",
    "Tbl_M_Star_CodeVerification_110125",
    "tbl_VendorvisekycstatusBK",
    "tbl_Vendorvisekycstatus_120126",
    "tbl_VendorvisekycstatusBK231225",
    "tbl_Vendorvisekycstatus_20012026",
    "tblUPITransactionDetails200226",
    "transactions_311225",
    "transactions171225"
)

$tablesDir = "c:\VCQRU-Project\sqlScript-ai\Tables"
$sqlScriptPath = "c:\VCQRU-Project\sqlScript-ai\SQLQuery_Script.sql"
$outputScriptPath = "c:\VCQRU-Project\sqlScript-ai\SQLQuery_Script_Updated.sql"

# 1. Remove files from Tables folder
Write-Host "--- Step 1: Removing files from Tables folder ---"
foreach ($table in $tablesToRemove) {
    $filePath = Join-Path $tablesDir "$table.sql"
    if (Test-Path $filePath) {
        Remove-Item $filePath -Force
        Write-Host "SUCCESS: Deleted $table.sql"
    }
    else {
        Write-Warning "NOT FOUND: $table.sql"
    }
}

# 2. Remove table definitions from SQLQuery_Script.sql
Write-Host "`n--- Step 2: Filtering SQLQuery_Script.sql ---"
$reader = New-Object System.IO.StreamReader($sqlScriptPath)
$writer = New-Object System.IO.StreamWriter($outputScriptPath)

$isSkipping = $false
$hasSeenCreateTable = $false
$currentTableToRemove = ""
$foundCount = 0

try {
    while (($line = $reader.ReadLine()) -ne $null) {
        
        # Detect start of a table block
        if ($line -match '/\*\*\*\*\*\* Object:  Table \[dbo\]\.\[(.*?)\]') {
            $tableName = $matches[1]
            if ($tablesToRemove -contains $tableName) {
                Write-Host "INFO: Found target table: $tableName"
                $isSkipping = $true
                $hasSeenCreateTable = $false
                $currentTableToRemove = $tableName
                $foundCount++
            }
        }
        
        if ($isSkipping) {
            # Check if we've reached the CREATE TABLE part within the block
            if ($line -match "CREATE TABLE \[dbo\]\.\[$currentTableToRemove\]") {
                $hasSeenCreateTable = $true
            }
            
            # Check if we've reached the end of the block (GO followed by anything else)
            # The block ends with a GO line after the CREATE TABLE statement.
            if ($line -eq "GO" -and $hasSeenCreateTable) {
                Write-Host "INFO: End of block for $currentTableToRemove"
                $isSkipping = $false
                $hasSeenCreateTable = $false
                continue # Skip this GO line as well
            }
            
            continue # Skip current line
        }

        $writer.WriteLine($line)
    }
}
finally {
    $reader.Close()
    $writer.Close()
}

Write-Host "`nSUMMARY: Removed $foundCount table definitions from SQL script."
Write-Host "Updated script saved to: $outputScriptPath"
