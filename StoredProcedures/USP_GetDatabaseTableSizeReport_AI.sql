CREATE OR ALTER PROCEDURE [dbo].[USP_GetDatabaseTableSizeReport_AI]
    @TableName NVARCHAR(256) = NULL,   -- Optional: filter by table name (e.g., 'M_Code')
    @TopN INT = NULL,                  -- Optional: Top N largest tables (e.g., 50)
    @MinSizeGB DECIMAL(18,2) = NULL    -- Optional: filter tables larger than X GB
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
        ;WITH TableSpaceData AS
        (
            SELECT
                s.name AS [SchemaName],
                t.name AS [TableName],
                t.object_id,
                
                (
                    SELECT SUM(p2.[rows])
                    FROM sys.partitions p2
                    WHERE p2.object_id = t.object_id
                      AND p2.index_id IN (0, 1)
                ) AS [TotalRows],
                
                CAST(SUM(a.total_pages) * 8.0 / 1024 / 1024 AS DECIMAL(18, 2)) AS [TotalSize_GB],
                CAST(SUM(a.used_pages) * 8.0 / 1024 / 1024 AS DECIMAL(18, 2)) AS [UsedSize_GB],
                CAST((SUM(a.total_pages) - SUM(a.used_pages)) * 8.0 / 1024 / 1024 AS DECIMAL(18, 2)) AS [UnusedSize_GB]

            FROM sys.tables t
            INNER JOIN sys.indexes i
                ON t.object_id = i.object_id
            INNER JOIN sys.partitions p
                ON i.object_id = p.object_id
                AND i.index_id = p.index_id
            INNER JOIN sys.allocation_units a
                ON p.partition_id = a.container_id
            INNER JOIN sys.schemas s
                ON t.schema_id = s.schema_id
            WHERE t.is_ms_shipped = 0
              AND (@TableName IS NULL OR t.name LIKE '%' + @TableName + '%')
            GROUP BY
                s.name,
                t.name,
                t.object_id
        ),
        TableUsageData AS
        (
            SELECT
                us.object_id,
                -- Last Read Time (Seek, Scan, Lookup)
                MAX(r.ReadTime) AS [LastReadTime],
                
                -- Last Write Time (Update, Insert, Delete)
                MAX(us.last_user_update) AS [LastWriteTime],
                
                SUM(ISNULL(us.user_seeks, 0) + ISNULL(us.user_scans, 0) + ISNULL(us.user_lookups, 0)) AS [TotalReads],
                SUM(ISNULL(us.user_updates, 0)) AS [TotalWrites]
            FROM sys.dm_db_index_usage_stats us
            CROSS APPLY (
                SELECT MAX(v.d) AS ReadTime
                FROM (VALUES (us.last_user_seek), (us.last_user_scan), (us.last_user_lookup)) AS v(d)
            ) r
            WHERE us.database_id = DB_ID()
            GROUP BY us.object_id
        )
        SELECT 
            tsd.[SchemaName],
            tsd.[TableName],
            tsd.[TotalRows],
            tsd.[TotalSize_GB],
            tsd.[UsedSize_GB],
            tsd.[UnusedSize_GB],
            
            -- Overall Last Access Time (Date & Time)
            a.MaxAccessTime AS [LastAccessTime],

            -- Last Activity Type: Read (Select), Write (Insert/Update/Delete), or No Activity
            CASE 
                WHEN tud.LastReadTime IS NULL AND tud.LastWriteTime IS NULL THEN 'No Activity'
                WHEN tud.LastWriteTime IS NOT NULL AND (tud.LastReadTime IS NULL OR tud.LastWriteTime >= tud.LastReadTime) 
                    THEN 'Write (Insert/Update/Delete)'
                ELSE 'Read (Select)'
            END AS [LastActivityType],

            tud.[LastReadTime],
            tud.[LastWriteTime],
            ISNULL(tud.[TotalReads], 0) AS [TotalReads],
            ISNULL(tud.[TotalWrites], 0) AS [TotalWrites]

        FROM TableSpaceData tsd
        LEFT JOIN TableUsageData tud
            ON tsd.object_id = tud.object_id
        CROSS APPLY (
            SELECT MAX(v.d) AS MaxAccessTime
            FROM (VALUES (tud.LastReadTime), (tud.LastWriteTime)) AS v(d)
        ) a
        WHERE (@MinSizeGB IS NULL OR tsd.TotalSize_GB >= @MinSizeGB)
        ORDER BY tsd.[TotalSize_GB] DESC
        OFFSET 0 ROWS
        FETCH NEXT CASE WHEN @TopN IS NOT NULL AND @TopN > 0 THEN @TopN ELSE 2147483647 END ROWS ONLY;

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO
