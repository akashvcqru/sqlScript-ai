IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[codeassign_tractrac]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[codeassign_tractrac](
        [MasterCode] [varchar](100) NOT NULL,
        [Pro_ID] [varchar](50) NULL,
        [MRP] [numeric](18, 2) NULL,
        [Mfd_Date] [datetime] NULL,
        [Exp_Date] [datetime] NULL,
        [Batch_No] [varchar](100) NULL,
        [SeriesStart] [varchar](100) NULL,
        [SeriesEnd] [varchar](100) NULL,
        [EntryDate] [datetime] NULL,
        [Dealer_Name] [nvarchar](150) NULL,
        [Dealer_Location] [nvarchar](150) NULL,
        [Contact_Information] [nvarchar](150) NULL,
        [Dispatch_Date] [datetime] NULL,
        [Invoice_Number] [nvarchar](50) NULL,
        CONSTRAINT [PK_codeassign_tractrac] PRIMARY KEY CLUSTERED 
        (
            [MasterCode] ASC
        )
    )
END
GO
