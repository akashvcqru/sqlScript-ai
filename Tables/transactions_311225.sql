/****** Object:  Table [dbo].[transactions_311225]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[transactions_311225](
	[TransactionsId] [int] IDENTITY(1,1) NOT NULL,
	[M_CounserID] [varchar](50) NULL,
	[CustomerName] [varchar](100) NULL,
	[BankAddress] [varchar](255) NULL,
	[BankName] [varchar](100) NULL,
	[AccountNumber] [varchar](100) NULL,
	[IFSCCode] [varchar](20) NULL,
	[Amount] [decimal](18, 2) NULL,
	[TransctionNumber] [varchar](100) NULL,
	[TransactionProcessDate] [varchar](100) NULL,
	[TransactionDate] [datetime] NULL,
	[CompId] [varchar](30) NULL,
	[MobileNumber] [varchar](15) NULL,
	[Branch] [varchar](200) NULL,
	[City] [varchar](200) NULL,
	[RTGS_Code] [varchar](255) NULL,
	[Issuccess] [int] NULL,
	[UPIIDs] [varchar](100) NULL,
	[created_date] [datetime] NULL
) ON [PRIMARY]
GO
