IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[M_ServiceSubscriptionTracTrace_MasterCodeLess]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[M_ServiceSubscriptionTracTrace_MasterCodeLess](
        [ID] [bigint] IDENTITY(1,1) NOT NULL,
        [SST_Id] [bigint] NOT NULL,
        [Pro_ID] [varchar](50) NULL,
        [Service_ID] [varchar](50) NULL,
        [Subscribe_Id] [varchar](50) NULL,
        [Dealer_Name] [nvarchar](150) NULL,
        [Dealer_Location] [nvarchar](150) NULL,
        [Mobile] [nvarchar](150) NULL,
        [Email] [nvarchar](150) NULL,
        [Invoice_Number] [nvarchar](50) NULL,
        [BatchSize] [int] NULL,
        [Batch_No] [varchar](100) NULL,
        [SeriesStart] [varchar](100) NULL,
        [SeriesEnd] [varchar](100) NULL,
        [Latitude] [nvarchar](50) NULL,
        [Longitude] [nvarchar](50) NULL,
        [EntryDate] [datetime] NULL DEFAULT (getdate()),
        CONSTRAINT [PK_M_ServiceSubscriptionTracTrace_MasterCodeLess] PRIMARY KEY CLUSTERED 
        (
            [ID] ASC
        )
    )
END
GO
