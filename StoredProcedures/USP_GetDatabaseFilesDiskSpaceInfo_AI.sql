CREATE OR ALTER PROCEDURE [dbo].[USP_GetDatabaseFilesDiskSpaceInfo_AI]
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
        SELECT
            DB_NAME(mf.database_id) AS [DatabaseName],
            mf.name AS [LogicalFileName],
            mf.physical_name AS [PhysicalFilePath],
            mf.type_desc AS [FileType],
            
            -- SQL File Size
            CAST(mf.size * 8.0 / 1024 / 1024 AS DECIMAL(18, 2)) AS [FileSize_GB],
            
            -- Host Drive
            vs.volume_mount_point AS [Drive],
            
            -- Auto-growth description
            CASE 
                WHEN mf.is_percent_growth = 1 THEN CONCAT(mf.growth, '%')
                ELSE CONCAT(CAST(mf.growth * 8.0 / 1024 AS DECIMAL(18, 2)), ' MB')
            END AS [AutoGrowthDescription]

        FROM sys.master_files mf
        INNER JOIN sys.databases d ON mf.database_id = d.database_id
        CROSS APPLY sys.dm_os_volume_stats(mf.database_id, mf.file_id) vs
        WHERE d.database_id > 4                                       -- Exclude core system DBs (master, tempdb, model, msdb)
          AND ISNULL(d.is_distributor, 0) = 0                        -- Exclude replication distribution DB
          AND d.source_database_id IS NULL                           -- Exclude database snapshots
          AND d.name NOT IN ('master', 'tempdb', 'model', 'msdb', 'distribution', 'SSISDB', 'DWDiagnostics', 'DWConfiguration', 'DWQueue')
          AND d.name NOT LIKE 'ReportServer%'                         -- Exclude SSRS system databases
          AND d.name NOT LIKE 'rdsadmin%'                             -- Exclude cloud/RDS system DBs
          AND d.name NOT LIKE 'mssqlsystemresource%'                  -- Exclude internal system resource DBs
        ORDER BY
            vs.volume_mount_point,
            d.name,
            mf.type_desc;

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO
