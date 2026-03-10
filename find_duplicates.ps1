$tablesDir = "c:\VCQRU-Project\sqlScript-ai\Tables"
$files = Get-ChildItem -Path $tablesDir -Filter *.sql | Select-Object -ExpandProperty Name
$results = @()

# Common suffixes identifying a duplicate/backup
$suffixes = @("BK", "_", "bk", "bak", "backup", "copy", "new", "Audit", "Temp")

foreach ($file in $files) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file)
    
    # Try to find if this file is a duplicate of another file
    # Pattern: [MainTable][Suffix][OptionalNumbers]
    
    # Check for direct matches where a shorter version exists
    foreach ($potentialMain in $files) {
        $mainName = [System.IO.Path]::GetFileNameWithoutExtension($potentialMain)
        
        # Skip if same file
        if ($baseName -eq $mainName) { continue }
        
        # If the current file starts with another file's name and has a suffix
        if ($baseName.StartsWith($mainName, [System.StringComparison]::OrdinalIgnoreCase)) {
            $remainder = $baseName.Substring($mainName.Length)
            
            # If the remainder looks like a duplicate suffix (digits or common keywords)
            if ($remainder -match '^([BK_]+)?\d+$' -or $remainder -match '^(BK|_bk|_Audit|_Temp|_bak|_backup|_new|copy|backup)$' -or $remainder -match '^_?\d+') {
                $results += [PSCustomObject]@{
                    MainTable     = $mainName
                    DuplicateFile = $file
                    Reason        = "Suffix: $remainder"
                }
                break # Found the main table for this duplicate
            }
        }
    }
}

if ($results.Count -gt 0) {
    Write-Host "Found $($results.Count) potential duplicate tables:"
    $results | Sort-Object MainTable | Format-Table -AutoSize
}
else {
    Write-Host "No duplicates found based on naming patterns."
}
