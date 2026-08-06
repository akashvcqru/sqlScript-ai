-- Migration: Create SetRequestLabelLimit table if not exists
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SetRequestLabelLimit]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[SetRequestLabelLimit](
        [Row_ID] [int] IDENTITY(1,1) NOT NULL,
        [Comp_ID] [varchar](10) NULL,
        [Pro_ID] [varchar](50) NULL,
        [MonthlyLimit] [bigint] NULL,
        [Req_Date] [datetime] NULL CONSTRAINT [DF_SetRequestLabelLimit_Req_Date] DEFAULT (getdate()),
        [IsApproved] [tinyint] NULL CONSTRAINT [DF_SetRequestLabelLimit_IsApproved] DEFAULT ((0)),
        [Approved_Date] [datetime] NULL,
        CONSTRAINT [PK_SetRequestLabelLimit] PRIMARY KEY CLUSTERED 
        (
            [Row_ID] ASC
        )
    );
END
GO
