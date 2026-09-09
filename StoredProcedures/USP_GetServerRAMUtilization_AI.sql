CREATE OR ALTER PROCEDURE [dbo].[USP_GetServerRAMUtilization_AI]
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
        SELECT
            GETDATE() AS [CheckTime],
         
            CAST(
                total_physical_memory_kb / 1024.0 / 1024.0
                AS DECIMAL(10,2)
            ) AS [TotalRAM_GB],
         
            CAST(
                available_physical_memory_kb / 1024.0 / 1024.0
                AS DECIMAL(10,2)
            ) AS [AvailableRAM_GB],
         
            CAST(
                (total_physical_memory_kb - available_physical_memory_kb)
                / 1024.0 / 1024.0
                AS DECIMAL(10,2)
            ) AS [UsedRAM_GB],
         
            CAST(
                (total_physical_memory_kb - available_physical_memory_kb)
                * 100.0 /
                NULLIF(total_physical_memory_kb,0)
                AS DECIMAL(5,2)
            ) AS [RAMUsedPercent],
         
            CASE
                WHEN
                    (total_physical_memory_kb - available_physical_memory_kb)
                    * 100.0 /
                    NULLIF(total_physical_memory_kb,0) < 75
                THEN 'Good'
         
                WHEN
                    (total_physical_memory_kb - available_physical_memory_kb)
                    * 100.0 /
                    NULLIF(total_physical_memory_kb,0) < 90
                THEN 'Warning'
         
                ELSE 'Critical'
            END AS [RAMStatus],
         
            system_memory_state_desc AS [MemoryStatus]
         
        FROM sys.dm_os_sys_memory;

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO
