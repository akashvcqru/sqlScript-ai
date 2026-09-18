-- =========================================================================================
-- Script Name: CREATE_TBL_TICKETFEEDBACK.sql
-- Description: Creates table tbl_TicketFeedback for storing ticket feedback & ratings.
-- Date: 2026-09-18
-- =========================================================================================

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'tbl_TicketFeedback')
BEGIN
    CREATE TABLE [dbo].[tbl_TicketFeedback](
        [FeedbackId] [int] IDENTITY(1,1) NOT NULL,
        [Comp_id] [varchar](100) NOT NULL,
        [M_Consumerid] [varchar](100) NOT NULL,
        [TicketId] [varchar](100) NOT NULL,
        [IsSatisfied] [bit] NOT NULL DEFAULT ((1)),
        [Rating] [int] NOT NULL DEFAULT ((5)),
        [FeedbackComment] [nvarchar](max) NULL,
        [CreatedOn] [datetime] NOT NULL DEFAULT (GETDATE())
     ) ON [PRIMARY];
END
GO
