$connStr = "Server=20.204.114.42\ProdAdmin,1433;Database=vcqru;User Id=sa;Password=VWRYE34@#!$@ESfgd;TrustServerCertificate=True;Connect Timeout=30;"
$conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
$conn.Open()

$cmd = $conn.CreateCommand()
$cmd.CommandText = @"
SELECT 
    BL.Points,
    BL.Cash,
    ISNULL(BL.ServiceName, 'NULL') AS ServiceName,
    BL.UpdateDate,
    BL.BuildLoyaltyOrReferralMCodeCheckid,
    PR.Pro_Name,
    M.Code1,
    M.Code2
FROM BLoyaltyPointsEarned BL
LEFT JOIN BuiltLoyaltyMCodeCheck BMC ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid
LEFT JOIN M_Consumer_M_Code MC ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
LEFT JOIN M_Code M ON MC.M_Codeid = M.Row_ID
LEFT JOIN Pro_Reg PR ON M.Pro_ID = PR.Pro_ID
WHERE BL.compid = 'Comp-1726' 
  AND BL.M_Consumerid = 989106
  AND (BL.ServiceName IS NULL OR LTRIM(RTRIM(BL.ServiceName)) = '')
ORDER BY BL.UpdateDate ASC;
"@

$ad = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
$ds = New-Object System.Data.DataSet
$ad.Fill($ds)
$ds.Tables[0] | Format-Table -AutoSize
$conn.Close()
