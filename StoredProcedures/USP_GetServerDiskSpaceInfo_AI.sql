CREATE OR ALTER PROCEDURE [dbo].[USP_GetServerDiskSpaceInfo_AI]
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
        ;WITH VolumeInfo AS
        (
            SELECT DISTINCT
                UPPER(LTRIM(RTRIM(vs.volume_mount_point))) AS [VolumeMountPoint],
                vs.total_bytes AS [TotalBytes],
                vs.available_bytes AS [FreeBytes]
            FROM sys.master_files mf
            CROSS APPLY sys.dm_os_volume_stats(mf.database_id, mf.file_id) vs
        )
        SELECT
            CASE 
                WHEN RIGHT([VolumeMountPoint], 1) = '\' THEN LEFT([VolumeMountPoint], LEN([VolumeMountPoint]) - 1)
                ELSE [VolumeMountPoint]
            END AS [Drive],
            
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
        FROM VolumeInfo
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
