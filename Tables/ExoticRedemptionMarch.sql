/****** Object:  Table [dbo].[ExoticRedemptionMarch]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ExoticRedemptionMarch](
	[MobileNumber] [nvarchar](255) NULL,
	[BankAddress] [nvarchar](255) NULL,
	[BankName] [nvarchar](255) NULL,
	[UPI ID] [nvarchar](255) NULL,
	[AccountNumber] [nvarchar](255) NULL,
	[IFSCCode] [nvarchar](255) NULL,
	[Amount] [float] NULL,
	[TransctionNumber/TransactionID] [nvarchar](255) NULL,
	[Updated Transaction ID] [nvarchar](255) NULL,
	[TransactionDate] [datetime] NULL,
	[Branch] [nvarchar](255) NULL,
	[City] [nvarchar](255) NULL,
	[Complete_code] [nvarchar](255) NULL,
	[Transaction_Status] [nvarchar](255) NULL,
	[Transaction Date] [datetime] NULL,
	[F16] [nvarchar](255) NULL,
	[F17] [nvarchar](255) NULL,
	[F18] [nvarchar](255) NULL,
	[F19] [nvarchar](255) NULL,
	[F20] [nvarchar](255) NULL,
	[F21] [nvarchar](255) NULL,
	[F22] [nvarchar](255) NULL,
	[F23] [nvarchar](255) NULL,
	[F24] [nvarchar](255) NULL,
	[F25] [nvarchar](255) NULL,
	[F26] [nvarchar](255) NULL
) ON [PRIMARY]
GO
