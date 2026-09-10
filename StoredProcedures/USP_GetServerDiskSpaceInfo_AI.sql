USE [Vcqru];
GO

CREATE OR ALTER PROCEDURE [dbo].[USP_GetServerDiskSpaceInfo_AI]
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    DECLARE @XpCmdShellEnabled INT = 0;
    SELECT @XpCmdShellEnabled = CAST(value_in_use AS INT) 
    FROM sys.configurations 
    WHERE name = 'xp_cmdshell';

    IF OBJECT_ID('tempdb..#DriveRaw') IS NOT NULL DROP TABLE #DriveRaw;
    CREATE TABLE #DriveRaw ( OutputLine NVARCHAR(4000) );

    IF @XpCmdShellEnabled = 1
    BEGIN
        INSERT INTO #DriveRaw (OutputLine)
        EXEC master.dbo.xp_cmdshell
        'powershell -NoProfile -Command "Get-CimInstance Win32_LogicalDisk -Filter ''DriveType=3'' | ForEach-Object { $Total=[math]::Round($_.Size/1GB,2); $Free=[math]::Round($_.FreeSpace/1GB,2); $Used=[math]::Round($Total-$Free,2); $UsedPct=[math]::Round(($Used/$Total)*100,2); $FreePct=[math]::Round(($Free/$Total)*100,2); [PSCustomObject]@{Drive=$_.DeviceID;TotalGB=$Total;UsedGB=$Used;FreeGB=$Free;UsedPercent=$UsedPct;FreePercent=$FreePct} | ConvertTo-Json -Compress }"';

        SELECT
            j.Drive AS [Drive],
            j.TotalGB AS [Total Space GB],
            j.UsedGB AS [Used Space GB],
            j.FreeGB AS [Free Space GB],
            j.UsedPercent AS [Used %],
            j.FreePercent AS [Free %],
            CASE
                WHEN j.FreePercent < 10 THEN 'CRITICAL'
                WHEN j.FreePercent < 20 THEN 'WARNING'
                ELSE 'HEALTHY'
            END AS [Disk Status]
        FROM #DriveRaw r
        CROSS APPLY OPENJSON(r.OutputLine)
        WITH
        (
            Drive       VARCHAR(10)   '$.Drive',
            TotalGB     DECIMAL(18,2) '$.TotalGB',
            UsedGB      DECIMAL(18,2) '$.UsedGB',
            FreeGB      DECIMAL(18,2) '$.FreeGB',
            UsedPercent DECIMAL(10,2) '$.UsedPercent',
            FreePercent DECIMAL(10,2) '$.FreePercent'
        ) j
        WHERE ISJSON(r.OutputLine) = 1
        ORDER BY j.Drive;

        DROP TABLE #DriveRaw;
    END
    ELSE
    BEGIN
        SELECT DISTINCT
            UPPER(vs.volume_mount_point) AS [Drive],
            CAST(vs.total_bytes / (1024.0 * 1024 * 1024) AS DECIMAL(18,2)) AS [Total Space GB],
            CAST((vs.total_bytes - vs.available_bytes) / (1024.0 * 1024 * 1024) AS DECIMAL(18,2)) AS [Used Space GB],
            CAST(vs.available_bytes / (1024.0 * 1024 * 1024) AS DECIMAL(18,2)) AS [Free Space GB],
            CAST(((vs.total_bytes - vs.available_bytes) * 100.0 / vs.total_bytes) AS DECIMAL(10,2)) AS [Used %],
            CAST((vs.available_bytes * 100.0 / vs.total_bytes) AS DECIMAL(10,2)) AS [Free %],
            CASE
                WHEN (vs.available_bytes * 100.0 / vs.total_bytes) < 10 THEN 'CRITICAL'
                WHEN (vs.available_bytes * 100.0 / vs.total_bytes) < 20 THEN 'WARNING'
                ELSE 'HEALTHY'
            END AS [Disk Status]
        FROM sys.master_files AS f
        CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.file_id) AS vs
        ORDER BY [Drive];
    END
END;
GO
