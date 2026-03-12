/****** Object:  Table [dbo].[mahindraRedeemption$]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[mahindraRedeemption$](
	[CustomerName] [nvarchar](255) NULL,
	[BankName] [nvarchar](255) NULL,
	[AccountNumber] [nvarchar](255) NULL,
	[IFSCCode] [nvarchar](255) NULL,
	[Amount] [float] NULL,
	[TransctionNumber] [nvarchar](255) NULL,
	[TransactionDate] [datetime] NULL,
	[MobileNumber] [float] NULL,
	[City] [nvarchar](255) NULL,
	[ConsumerId] [int] NULL
) ON [PRIMARY]
GO
