/****** Object:  Table [dbo].[VRKableRedemptionMay]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[VRKableRedemptionMay](
	[CustomerName] [nvarchar](255) NULL,
	[BankAddress] [nvarchar](255) NULL,
	[BankName] [nvarchar](255) NULL,
	[AccountNumber] [nvarchar](255) NULL,
	[IFSCCode] [nvarchar](255) NULL,
	[Amount] [float] NULL,
	[TransctionNumber] [nvarchar](255) NULL,
	[TransactionProcessDate] [nvarchar](255) NULL,
	[TransactionDate] [nvarchar](255) NULL,
	[CompId] [nvarchar](255) NULL,
	[MobileNumber] [nvarchar](255) NULL,
	[Branch] [nvarchar](255) NULL,
	[City] [nvarchar](255) NULL,
	[RTGS_Code] [nvarchar](255) NULL,
	[Issuccess] [float] NULL,
	[bpstatus] [nvarchar](255) NULL,
	[Claim ID] [float] NULL,
	[F18] [nvarchar](255) NULL,
	[F19] [nvarchar](255) NULL
) ON [PRIMARY]
GO
