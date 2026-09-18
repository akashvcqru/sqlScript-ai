-- Check if Agent Job is supported in the current edition
IF (SELECT SERVERPROPERTY('EngineEdition')) NOT IN (2, 3, 8)
BEGIN
    PRINT 'SQL Server Agent Jobs are not supported on this SQL Server edition. Skipping job creation.';
END
ELSE
BEGIN
    DECLARE @JobName NVARCHAR(128) = N'Daily_FillThreeCombinedActivityReports';
    DECLARE @DatabaseName NVARCHAR(128) = DB_NAME();

    -- Delete job if it already exists
    IF EXISTS (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = @JobName)
    BEGIN
        PRINT 'Deleting existing job: ' + @JobName;
        EXEC msdb.dbo.sp_delete_job @job_name = @JobName, @delete_unused_schedule = 1;
    END

    -- Create job
    DECLARE @jobId BINARY(16);
    EXEC msdb.dbo.sp_add_job 
        @job_name = @JobName, 
        @enabled = 1, 
        @description = N'Daily job to iterate company by company and populate tbl_BL_CodesActivityReport_AI, tbl_BL_PaymentClaimReport_AI, and tbl_BL_UPIPayoutReport_AI.',
        @category_name = N'[Uncategorized (Local)]',
        @owner_login_name = N'sa',
        @job_id = @jobId OUTPUT;

    -- Add Job Step
    EXEC msdb.dbo.sp_add_jobstep 
        @job_id = @jobId, 
        @step_name = N'Execute Daily Fill SP', 
        @step_id = 1, 
        @cmdexec_success_code = 0, 
        @on_success_action = 1, -- Quit with success
        @on_fail_action = 2,    -- Quit with failure
        @subsystem = N'TSQL', 
        @command = N'EXEC [dbo].[USP_FillThreeCombinedActivityReports_AllCompanies_AI]', 
        @database_name = @DatabaseName;

    -- Add Schedule (Daily at 12:00 AM midnight)
    DECLARE @scheduleId INT;
    EXEC msdb.dbo.sp_add_schedule 
        @schedule_name = N'Daily_12AM_Schedule', 
        @enabled = 1, 
        @freq_type = 4,             -- Daily
        @freq_interval = 1,         -- Every 1 day
        @freq_subday_type = 1,      -- At the specified time
        @active_start_time = 000000, -- 12:00:00 AM midnight (HHMMSS)
        @schedule_id = @scheduleId OUTPUT;

    -- Attach Schedule
    EXEC msdb.dbo.sp_attach_schedule 
        @job_id = @jobId, 
        @schedule_id = @scheduleId;

    -- Add Job Server
    EXEC msdb.dbo.sp_add_jobserver 
        @job_id = @jobId, 
        @server_name = N'(local)';

    PRINT 'SQL Server Agent Job ' + @JobName + ' created successfully in database ' + @DatabaseName + '.';
END
GO
