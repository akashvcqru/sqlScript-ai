CREATE OR ALTER PROCEDURE [dbo].[USP_GetServerDiskSpaceInfo_AI]
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
        -- Table variable to capture xp_cmdshell output
        DECLARE @DriveInfo TABLE
        (
            OutputLine NVARCHAR(4000)
        );

        -- Execute PowerShell via xp_cmdshell to query all fixed logical drives (DriveType=3)
        INSERT INTO @DriveInfo (OutputLine)
        EXEC master..xp_cmdshell 
        'powershell -NoProfile -Command "Get-CimInstance Win32_LogicalDisk -Filter ''DriveType=3'' | ForEach-Object { Write-Output ($_.DeviceID + ''|'' + $_.Size + ''|'' + $_.FreeSpace) }"';

        ;WITH RawData AS
        (
            SELECT
                LTRIM(RTRIM(OutputLine)) AS OutputLine,
                CHARINDEX('|', OutputLine) AS P1,
                CHARINDEX('|', OutputLine, CHARINDEX('|', OutputLine) + 1) AS P2
            FROM @DriveInfo
            WHERE OutputLine IS NOT NULL
              AND OutputLine LIKE '%|%|%'
        ),
        DriveData AS
        (
            SELECT
                LEFT(OutputLine, P1 - 1) AS [Drive],
                TRY_CONVERT(DECIMAL(38,0), LTRIM(RTRIM(SUBSTRING(OutputLine, P1 + 1, P2 - P1 - 1)))) AS [TotalBytes],
                TRY_CONVERT(DECIMAL(38,0), LTRIM(RTRIM(SUBSTRING(OutputLine, P2 + 1, LEN(OutputLine))))) AS [FreeBytes]
            FROM RawData
        )
        SELECT
            [Drive],
            
            /* Total Space in GB */
            CAST(TotalBytes / 1073741824.0 AS DECIMAL(18, 2)) AS [TotalSpace_GB],
            
            /* Used Space in GB */
            CAST((TotalBytes - FreeBytes) / 1073741824.0 AS DECIMAL(18, 2)) AS [UsedSpace_GB],
            
            /* Free Space in GB */
            CAST(FreeBytes / 1073741824.0 AS DECIMAL(18, 2)) AS [FreeSpace_GB],
            
            /* Used Percentage */
            CAST(((TotalBytes - FreeBytes) * 100.0) / NULLIF(TotalBytes, 0) AS DECIMAL(10, 2)) AS [UsedPercent],
            
            /* Free Percentage */
            CAST((FreeBytes * 100.0) / NULLIF(TotalBytes, 0) AS DECIMAL(10, 2)) AS [FreePercent]
        FROM DriveData
        WHERE TotalBytes IS NOT NULL 
          AND FreeBytes IS NOT NULL
        ORDER BY [Drive];

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO
