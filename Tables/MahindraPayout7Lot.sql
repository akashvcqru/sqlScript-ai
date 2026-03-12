/****** Object:  Table [dbo].[MahindraPayout7Lot]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MahindraPayout7Lot](
	[SL NO#] [float] NULL,
	[Mobile_Number] [nvarchar](255) NULL,
	[Input] [float] NULL,
	[Employee Code] [nvarchar](255) NULL,
	[Techmaster ID] [nvarchar](255) NULL,
	[Mstar ID] [nvarchar](255) NULL,
	[RID] [float] NULL,
	[Dealer Code] [nvarchar](255) NULL,
	[State] [nvarchar](255) NULL,
	[Designation] [nvarchar](255) NULL,
	[Customer Name] [nvarchar](255) NULL,
	[Bank Name] [nvarchar](255) NULL,
	[Account holder Name] [nvarchar](255) NULL,
	[AccountNo] [nvarchar](255) NULL,
	[Ifsccode] [nvarchar](255) NULL,
	[Branch] [nvarchar](255) NULL,
	[City] [nvarchar](255) NULL,
	[Address] [nvarchar](255) NULL,
	[Adhar Card Number] [nvarchar](255) NULL,
	[Amount Payable 7th Lot] [float] NULL,
	[Txn Date] [datetime] NULL,
	[Txn Time] [datetime] NULL,
	[Txn ID] [nvarchar](255) NULL,
	[Txn Status] [nvarchar](255) NULL,
	[Remarks] [nvarchar](255) NULL
) ON [PRIMARY]
GO
