CREATE OR ALTER PROCEDURE [dbo].[USP_GetDatabaseIndexUsageReport_AI]
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
        SELECT
            DB_NAME() AS DatabaseName,
            SCHEMA_NAME(t.schema_id) AS SchemaName,
            t.name AS TableName,
            i.name AS IndexName,
            i.index_id AS IndexID,
            i.type_desc AS IndexType,
            SUM(ps.row_count) AS TableRows,
            CAST(
                SUM(ps.reserved_page_count) * 8.0 / 1024 AS DECIMAL(18, 2)
            ) AS IndexSizeMB,
            ISNULL(us.user_seeks, 0) AS UserSeeks,
            ISNULL(us.user_scans, 0) AS UserScans,
            ISNULL(us.user_lookups, 0) AS UserLookups,
            ISNULL(us.user_updates, 0) AS UserUpdates,
            CASE 
                WHEN ISNULL(us.user_seeks, 0)
                   + ISNULL(us.user_scans, 0)
                   + ISNULL(us.user_lookups, 0) = 0 THEN 'Not In Use'
                ELSE 'In Use'
            END AS IndexUsageStatus,
            us.last_user_seek AS LastUserSeek,
            us.last_user_scan AS LastUserScan,
            us.last_user_lookup AS LastUserLookup,
            us.last_user_update AS LastUserUpdate
        FROM sys.tables AS t
        INNER JOIN sys.indexes AS i
            ON t.object_id = i.object_id
        INNER JOIN sys.dm_db_partition_stats AS ps
            ON i.object_id = ps.object_id
            AND i.index_id = ps.index_id
        LEFT JOIN sys.dm_db_index_usage_stats AS us
            ON i.object_id = us.object_id
            AND i.index_id = us.index_id
            AND us.database_id = DB_ID()
        WHERE
            i.index_id > 0
            AND i.is_disabled = 0
            AND i.is_hypothetical = 0
        GROUP BY
            t.schema_id,
            t.name,
            i.name,
            i.index_id,
            i.type_desc,
            us.user_seeks,
            us.user_scans,
            us.user_lookups,
            us.user_updates,
            us.last_user_seek,
            us.last_user_scan,
            us.last_user_lookup,
            us.last_user_update
        ORDER BY
            CASE 
                WHEN ISNULL(us.user_seeks, 0)
                   + ISNULL(us.user_scans, 0)
                   + ISNULL(us.user_lookups, 0) = 0 THEN 0
                ELSE 1
            END,
            IndexSizeMB DESC;

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO
