IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[codeassign_tractrac]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[codeassign_tractrac](
        [ID] [bigint] IDENTITY(1,1) NOT NULL,
        [mastercode] [varchar](100) NOT NULL,
        [Dealer_Name] [nvarchar](150) NULL,
        [Dealer_Location] [nvarchar](150) NULL,
        [Contact_Information] [nvarchar](150) NULL,
        [Dispatch_Date] [datetime] NULL,
        [Invoice_Number] [nvarchar](50) NULL,
        [Latitude] [nvarchar](50) NULL,
        [Longitude] [nvarchar](50) NULL,
        [entry_date] [datetime] NULL DEFAULT (getdate()),
        [status] [int] NULL DEFAULT ((0)),
        [isdelete] [int] NULL DEFAULT ((0)),
        [Pro_ID] [varchar](50) NULL,
        [MRP] [numeric](18, 2) NULL,
        [Mfd_Date] [datetime] NULL,
        [Exp_Date] [datetime] NULL,
        [Batch_No] [varchar](100) NULL,
        [SeriesStart] [varchar](100) NULL,
        [SeriesEnd] [varchar](100) NULL,
        CONSTRAINT [PK_codeassign_tractrac] PRIMARY KEY CLUSTERED 
        (
            [mastercode] ASC
        )
    )
END
GO
