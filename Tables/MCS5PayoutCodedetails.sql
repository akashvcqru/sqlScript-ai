/****** Object:  Table [dbo].[MCS5PayoutCodedetails]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MCS5PayoutCodedetails](
	[SL NO#] [float] NULL,
	[Mobile_Number] [numeric](18, 0) NULL,
	[Technician ID] [nvarchar](255) NULL,
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
	[Payout Amount] [float] NULL,
	[1st LoT] [float] NULL,
	[2nd Lot] [float] NULL,
	[3rd Lot] [float] NULL,
	[4th Lot] [float] NULL,
	[Payout Amount Lot 5] [float] NULL,
	[Transaction ID] [nvarchar](255) NULL,
	[Status] [nvarchar](255) NULL,
	[Transaction Date] [datetime] NULL,
	[Remarks By VCQRU] [nvarchar](255) NULL
) ON [PRIMARY]
GO
