-- =============================================
-- Table: tbl_MailJobExecutionHistory
-- Description: Table to maintain execution history and status logs for all background mail shoot jobs
-- =============================================

USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tbl_MailJobExecutionHistory]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[tbl_MailJobExecutionHistory]
    (
        [HistoryId] BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [JobName] NVARCHAR(150) NOT NULL,               -- e.g. SummaryDataReportEmailBackgroundService, LastDayFraudClaimEmailBackgroundService
        [ScheduleType] NVARCHAR(50) NULL,              -- e.g. Daily, Weekly, Monthly, Quarterly, Triggered
        [CompId] NVARCHAR(50) NULL,                     -- Target Company ID (if company specific)
        [Recipients] NVARCHAR(MAX) NULL,                -- Recipient email addresses
        [Subject] NVARCHAR(500) NULL,                   -- Email Subject
        [AttachmentCount] INT NOT NULL DEFAULT 0,       -- Number of attachments attached to email
        [Status] NVARCHAR(50) NOT NULL,                 -- SUCCESS, FAILED, IN_PROGRESS, SKIPPED
        [ErrorMessage] NVARCHAR(MAX) NULL,              -- Error/Exception message if job failed
        [StackTrace] NVARCHAR(MAX) NULL,                -- Exception stack trace details
        [FailedStep] NVARCHAR(150) NULL,                -- Step or SP where failure occurred (e.g. SP_BL_GetCodesActivityReport_AI, SMTP_SEND)
        [ExecutionStartTime] DATETIME NOT NULL DEFAULT GETDATE(),
        [ExecutionEndTime] DATETIME NULL,
        [DurationMs] BIGINT NULL                        -- Total execution duration in milliseconds
    );

    -- Indexes for fast querying & filtering
    CREATE NONCLUSTERED INDEX [IX_tbl_MailJobExecutionHistory_JobName_Status] 
    ON [dbo].[tbl_MailJobExecutionHistory] ([JobName], [Status], [ExecutionStartTime] DESC);

    CREATE NONCLUSTERED INDEX [IX_tbl_MailJobExecutionHistory_CompId] 
    ON [dbo].[tbl_MailJobExecutionHistory] ([CompId], [ExecutionStartTime] DESC);

    PRINT 'Table tbl_MailJobExecutionHistory created successfully.';
END
ELSE
BEGIN
    PRINT 'Table tbl_MailJobExecutionHistory already exists.';
END
GO
