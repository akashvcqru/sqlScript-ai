/****** Object:  Table [dbo].[Mcs43rdlotrecovery]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Mcs43rdlotrecovery](
	[Sl No#] [float] NULL,
	[DealerCode] [nvarchar](255) NULL,
	[State] [nvarchar](255) NULL,
	[Designation] [nvarchar](255) NULL,
	[TechnicianID] [float] NULL,
	[Mobile Number] [nvarchar](255) NULL,
	[CustomerName] [nvarchar](255) NULL,
	[AccountholderName] [nvarchar](255) NULL,
	[AccountNo] [nvarchar](255) NULL,
	[Ifsccode] [nvarchar](255) NULL,
	[BankName] [nvarchar](255) NULL,
	[Branch] [nvarchar](255) NULL,
	[City] [nvarchar](255) NULL,
	[Address] [nvarchar](255) NULL,
	[AdharCardNumber] [nvarchar](255) NULL,
	[PayoutDoneon7thDec22] [float] NULL,
	[TransactionID7thDec22] [nvarchar](255) NULL,
	[RemarksByVCQRU] [nvarchar](255) NULL
) ON [PRIMARY]
GO
