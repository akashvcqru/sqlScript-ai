CREATE OR ALTER PROCEDURE [dbo].[USP_GetStoredProcedureUsageReport_AI]
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
        ;WITH ProcedureUsage AS
        (
            SELECT
                database_id,
                object_id,
                SUM(execution_count) AS ExecutionCount,
                MIN(cached_time) AS FirstCachedTime,
                MAX(last_execution_time) AS LastExecutionTime
            FROM sys.dm_exec_procedure_stats
            WHERE database_id = DB_ID()
            GROUP BY database_id, object_id
        )
        SELECT
            DB_NAME() AS DatabaseName,
            SCHEMA_NAME(p.schema_id) AS SchemaName,
            p.name AS StoredProcedureName,
            p.create_date AS CreatedDate,
            p.modify_date AS LastModifiedDate,
         
            ISNULL(u.ExecutionCount, 0) AS ExecutionCount,
            u.FirstCachedTime,
            u.LastExecutionTime,
         
            CASE
                WHEN u.object_id IS NULL
                    THEN 'No Execution Found'
                ELSE 'In Use'
            END AS ProcedureUsageStatus,
         
            CASE
                WHEN p.is_ms_shipped = 1
                    THEN 'System Procedure'
                ELSE 'User Procedure'
            END AS ProcedureType
         
        FROM sys.procedures AS p
        LEFT JOIN ProcedureUsage AS u
            ON p.object_id = u.object_id
        WHERE
            p.is_ms_shipped = 0
        ORDER BY
            CASE WHEN u.object_id IS NULL THEN 0 ELSE 1 END,
            u.LastExecutionTime,
            p.name;

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO
