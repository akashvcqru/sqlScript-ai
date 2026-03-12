/****** Object:  Table [dbo].[BSCCashPayout]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BSCCashPayout](
	[User Number] [nvarchar](255) NULL,
	[Account Holder Name] [nvarchar](255) NULL,
	[Bank Name] [nvarchar](255) NULL,
	[Account Number] [nvarchar](255) NULL,
	[IFSC Code] [nvarchar](255) NULL,
	[Branch Name] [nvarchar](255) NULL,
	[Count of Completecode] [float] NULL,
	[Sum of Amount_Won] [float] NULL,
	[Txn Date] [datetime] NULL,
	[Txn ID] [nvarchar](255) NULL,
	[Status] [nvarchar](255) NULL,
	[F12] [nvarchar](255) NULL,
	[F13] [nvarchar](255) NULL,
	[F14] [nvarchar](255) NULL
) ON [PRIMARY]
GO
