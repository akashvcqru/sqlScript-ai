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
        )
        SELECT 
            [SchemaName],
            [TableName],
            [TotalRows],
            [TotalSize_GB],
            [UsedSize_GB],
            [UnusedSize_GB]
        FROM TableSpaceData
        WHERE (@MinSizeGB IS NULL OR TotalSize_GB >= @MinSizeGB)
        ORDER BY [TotalSize_GB] DESC
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
