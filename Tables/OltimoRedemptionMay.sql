/****** Object:  Table [dbo].[OltimoRedemptionMay]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OltimoRedemptionMay](
	[CustomerName] [nvarchar](255) NULL,
	[BankAddress] [nvarchar](255) NULL,
	[BankName] [nvarchar](255) NULL,
	[AccountNumber] [nvarchar](255) NULL,
	[IFSCCode] [nvarchar](255) NULL,
	[Amount] [float] NULL,
	[TransctionNumber] [nvarchar](255) NULL,
	[TransactionProcessDate] [datetime] NULL,
	[TransactionDate] [datetime] NULL,
	[CompId] [nvarchar](255) NULL,
	[MobileNumber] [nvarchar](255) NULL,
	[Branch] [nvarchar](255) NULL,
	[City] [nvarchar](255) NULL,
	[RTGS_Code] [nvarchar](255) NULL,
	[Issuccess] [float] NULL,
	[Enquiry Mode] [nvarchar](255) NULL,
	[Complete Code] [nvarchar](255) NULL,
	[Enquiry Date ] [datetime] NULL,
	[bpstatus] [nvarchar](255) NULL
) ON [PRIMARY]
GO
