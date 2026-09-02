CREATE OR ALTER PROCEDURE [dbo].[USP_GetServerAgentJobs_AI]
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
        SELECT
            j.name AS JobName,
            
            CASE j.enabled
                WHEN 1 THEN 'Enabled'
                ELSE 'Disabled'
            END AS JobStatus,
         
            ISNULL(s.name, 'No Schedule') AS ScheduleName,
         
            CASE
                WHEN s.schedule_id IS NULL THEN 'Not Scheduled'
                WHEN s.enabled = 0 THEN 'Schedule Disabled'
                ELSE 'Schedule Enabled'
            END AS ScheduleStatus,
         
            CASE s.freq_type
                WHEN 1   THEN 'One Time'
                WHEN 4   THEN 'Daily'
                WHEN 8   THEN 'Weekly'
                WHEN 16  THEN 'Monthly'
                WHEN 32  THEN 'Monthly Relative'
                WHEN 64  THEN 'When SQL Agent Starts'
                WHEN 128 THEN 'When Computer Is Idle'
                ELSE 'Not Scheduled'
            END AS ScheduleFrequency,
         
            CASE
                WHEN s.freq_type = 4
                    THEN CONCAT('Every ', s.freq_interval, ' day(s)')
         
                WHEN s.freq_type = 8
                    THEN CONCAT(
                        'Every ', s.freq_recurrence_factor, ' week(s): ',
                        CASE WHEN s.freq_interval & 1  = 1  THEN 'Sunday '   ELSE '' END,
                        CASE WHEN s.freq_interval & 2  = 2  THEN 'Monday '   ELSE '' END,
                        CASE WHEN s.freq_interval & 4  = 4  THEN 'Tuesday '  ELSE '' END,
                        CASE WHEN s.freq_interval & 8  = 8  THEN 'Wednesday ' ELSE '' END,
                        CASE WHEN s.freq_interval & 16 = 16 THEN 'Thursday ' ELSE '' END,
                        CASE WHEN s.freq_interval & 32 = 32 THEN 'Friday '   ELSE '' END,
                        CASE WHEN s.freq_interval & 64 = 64 THEN 'Saturday'  ELSE '' END
                    )
         
                WHEN s.freq_type = 16
                    THEN CONCAT('Day ', s.freq_interval, ' of every ',
                                s.freq_recurrence_factor, ' month(s)')
         
                WHEN s.freq_type = 1
                    THEN 'One-time execution'
         
                ELSE ''
            END AS ScheduleDetails,
         
            CASE
                WHEN s.schedule_id IS NULL THEN NULL
                ELSE STUFF(
                        STUFF(
                            RIGHT('000000' + CAST(s.active_start_time AS VARCHAR(6)), 6),
                            3, 0, ':'
                        ),
                        6, 0, ':'
                     )
            END AS ScheduledTime,
         
            CASE
                WHEN h.run_date IS NULL OR h.run_date = 0 THEN NULL
                ELSE msdb.dbo.agent_datetime(h.run_date, h.run_time)
            END AS LastRunDateTime,
         
            CASE h.run_status
                WHEN 0 THEN 'Failed'
                WHEN 1 THEN 'Succeeded'
                WHEN 2 THEN 'Retry'
                WHEN 3 THEN 'Cancelled'
                WHEN 4 THEN 'In Progress'
                ELSE 'Never Executed'
            END AS LastRunStatus,
         
            CASE
                WHEN h.run_duration IS NULL THEN NULL
                ELSE CONCAT(
                    DurationInfo.DurationSeconds / 3600,
                    ':',
                    RIGHT(
                        '00' + CAST(
                            (DurationInfo.DurationSeconds % 3600) / 60
                            AS VARCHAR(2)
                        ),
                        2
                    ),
                    ':',
                    RIGHT(
                        '00' + CAST(
                            DurationInfo.DurationSeconds % 60
                            AS VARCHAR(2)
                        ),
                        2
                    )
                )
            END AS LastRunDuration_HHMMSS,
         
            CASE
                WHEN js.next_run_date IS NULL OR js.next_run_date = 0 THEN NULL
                ELSE msdb.dbo.agent_datetime(
                    js.next_run_date,
                    js.next_run_time
                )
            END AS NextRunDateTime,
         
            h.message AS LastRunMessage
         
        FROM msdb.dbo.sysjobs AS j
         
        LEFT JOIN msdb.dbo.sysjobschedules AS js
            ON j.job_id = js.job_id
         
        LEFT JOIN msdb.dbo.sysschedules AS s
            ON js.schedule_id = s.schedule_id
         
        OUTER APPLY
        (
            SELECT TOP (1)
                sh.run_date,
                sh.run_time,
                sh.run_duration,
                sh.run_status,
                sh.message
            FROM msdb.dbo.sysjobhistory AS sh
            WHERE
                sh.job_id = j.job_id
                AND sh.step_id = 0
            ORDER BY sh.instance_id DESC
        ) AS h
         
        OUTER APPLY
        (
            SELECT
                CASE
                    WHEN h.run_duration IS NULL THEN NULL
                    ELSE
                        (h.run_duration / 10000) * 3600
                        + ((h.run_duration % 10000) / 100) * 60
                        + (h.run_duration % 100)
                END AS DurationSeconds
        ) AS DurationInfo
         
        ORDER BY
            j.name,
            s.name;

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO
