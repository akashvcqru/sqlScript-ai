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
            CAST(mf.size * 8.0 / 1024 AS DECIMAL(18, 2)) AS [FileSize_MB],
            CAST(mf.size * 8.0 / 1024 / 1024 AS DECIMAL(18, 2)) AS [FileSize_GB],
            
            -- Drive / Volume
            vs.volume_mount_point AS [Drive],
            
            -- Total Drive Size
            CAST(vs.total_bytes / 1073741824.0 AS DECIMAL(18, 2)) AS [DriveTotal_GB],
            
            -- Free Drive Space
            CAST(vs.available_bytes / 1073741824.0 AS DECIMAL(18, 2)) AS [DriveFree_GB],
            
            -- Used Drive Space
            CAST((vs.total_bytes - vs.available_bytes) / 1073741824.0 AS DECIMAL(18, 2)) AS [DriveUsed_GB],
            
            -- Free %
            CAST((vs.available_bytes * 100.0) / NULLIF(vs.total_bytes, 0) AS DECIMAL(10, 2)) AS [DriveFreePercent],
            
            -- Used %
            CAST(((vs.total_bytes - vs.available_bytes) * 100.0) / NULLIF(vs.total_bytes, 0) AS DECIMAL(10, 2)) AS [DriveUsedPercent],
            
            -- Growth settings
            mf.growth AS [Growth],
            mf.is_percent_growth AS [IsPercentGrowth],
            CASE 
                WHEN mf.is_percent_growth = 1 THEN CONCAT(mf.growth, '%')
                ELSE CONCAT(CAST(mf.growth * 8.0 / 1024 AS DECIMAL(18, 2)), ' MB')
            END AS [AutoGrowthDescription]

        FROM sys.master_files mf
        CROSS APPLY sys.dm_os_volume_stats(mf.database_id, mf.file_id) vs
        ORDER BY
            vs.volume_mount_point,
            DB_NAME(mf.database_id),
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
