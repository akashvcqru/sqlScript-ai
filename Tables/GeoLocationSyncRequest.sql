/****** Object:  Table [dbo].[GeoLocationSyncRequest]    Script Date: 10/8/2026 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.GeoLocationSyncRequest', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[GeoLocationSyncRequest] (
        [Id] [bigint] IDENTITY(1,1) NOT NULL,
        [JobId] [nvarchar](100) NOT NULL,
        [CompId] [nvarchar](50) NULL,
        [DatePreset] [nvarchar](50) NULL,
        [FromDate] [nvarchar](50) NULL,
        [ToDate] [nvarchar](50) NULL,
        [TotalFound] [int] NOT NULL CONSTRAINT [DF_GeoLocationSyncRequest_TotalFound] DEFAULT ((0)),
        [ProcessedCount] [int] NOT NULL CONSTRAINT [DF_GeoLocationSyncRequest_ProcessedCount] DEFAULT ((0)),
        [FailedCount] [int] NOT NULL CONSTRAINT [DF_GeoLocationSyncRequest_FailedCount] DEFAULT ((0)),
        [ProgressPercentage] [nvarchar](20) NOT NULL CONSTRAINT [DF_GeoLocationSyncRequest_ProgressPercentage] DEFAULT ('0.0%'),
        [Status] [nvarchar](50) NOT NULL CONSTRAINT [DF_GeoLocationSyncRequest_Status] DEFAULT ('InProgress'),
        [ErrorMessage] [nvarchar](max) NULL,
        [CreatedAt] [datetime] NOT NULL CONSTRAINT [DF_GeoLocationSyncRequest_CreatedAt] DEFAULT (getdate()),
        [UpdatedAt] [datetime] NOT NULL CONSTRAINT [DF_GeoLocationSyncRequest_UpdatedAt] DEFAULT (getdate()),
        [CompletedAt] [datetime] NULL,
        CONSTRAINT [PK_GeoLocationSyncRequest] PRIMARY KEY CLUSTERED 
        (
            [Id] ASC
        ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
    ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_GeoLocationSyncRequest_JobId')
    BEGIN
        CREATE NONCLUSTERED INDEX [IX_GeoLocationSyncRequest_JobId] 
        ON [dbo].[GeoLocationSyncRequest] ([JobId] ASC);
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_GeoLocationSyncRequest_CompId_Id')
    BEGIN
        CREATE NONCLUSTERED INDEX [IX_GeoLocationSyncRequest_CompId_Id] 
        ON [dbo].[GeoLocationSyncRequest] ([CompId] ASC, [Id] DESC);
    END;
END
GO
