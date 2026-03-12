/****** Object:  Table [dbo].[OltimoDupTrans]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OltimoDupTrans](
	[MobileNumber] [nvarchar](255) NULL,
	[BankAddress] [nvarchar](255) NULL,
	[BankName] [nvarchar](255) NULL,
	[UPI ID] [nvarchar](255) NULL,
	[AccountNumber] [nvarchar](255) NULL,
	[IFSCCode] [nvarchar](255) NULL,
	[Amount] [float] NULL,
	[TransctionNumber/TransactionID] [nvarchar](255) NULL,
	[TransactionDate] [nvarchar](255) NULL,
	[Branch] [nvarchar](255) NULL,
	[City] [nvarchar](255) NULL,
	[Complete_code] [nvarchar](255) NULL,
	[Transaction_Status] [nvarchar](255) NULL,
	[Transaction Date] [datetime] NULL,
	[F15] [nvarchar](255) NULL,
	[F16] [nvarchar](255) NULL
) ON [PRIMARY]
GO
