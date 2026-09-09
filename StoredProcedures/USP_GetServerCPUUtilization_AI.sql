CREATE OR ALTER PROCEDURE [dbo].[USP_GetServerCPUUtilization_AI]
    @HoursBack INT = 8
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
        ;WITH CPUHistory AS
        (
            SELECT
                DATEADD
                (
                    MILLISECOND,
                    -1 * (si.ms_ticks - rb.[timestamp]),
                    GETDATE()
                ) AS EventTime,
         
                rb.record.value(
                    '(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]',
                    'int'
                ) AS SystemIdle,
         
                rb.record.value(
                    '(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]',
                    'int'
                ) AS SQLCPU
         
            FROM
            (
                SELECT
                    [timestamp],
                    CONVERT(XML, record) AS record
                FROM sys.dm_os_ring_buffers
                WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR'
                  AND record LIKE '%<SystemHealth>%'
            ) rb
         
            CROSS JOIN sys.dm_os_sys_info si
        )
         
        SELECT
            DATEADD(
                HOUR,
                DATEDIFF(HOUR, 0, EventTime),
                0
            ) AS [Hour],
         
            CAST(
                AVG(100 - SystemIdle)
                AS DECIMAL(5,1)
            ) AS [AvgServerCPUPercent],
         
            MAX(100 - SystemIdle)
                AS [PeakServerCPUPercent],
         
            CAST(
                AVG(SQLCPU)
                AS DECIMAL(5,1)
            ) AS [AvgSQLCPUPercent],
         
            MAX(SQLCPU)
                AS [PeakSQLCPUPercent]
         
        FROM CPUHistory
         
        WHERE EventTime >= DATEADD(HOUR, -1 * @HoursBack, GETDATE())
         
        GROUP BY
            DATEADD(
                HOUR,
                DATEDIFF(HOUR, 0, EventTime),
                0
            )
         
        ORDER BY [Hour] DESC;

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO
