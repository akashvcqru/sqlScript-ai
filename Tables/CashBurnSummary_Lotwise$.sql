/****** Object:  Table [dbo].[CashBurnSummary_Lotwise$]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CashBurnSummary_Lotwise$](
	[Scheme Name] [nvarchar](255) NULL,
	[Lot ] [nvarchar](255) NULL,
	[Redemption Period] [nvarchar](255) NULL,
	[Approval Date] [nvarchar](255) NULL,
	[Count Of User] [float] NULL,
	[Approval Gross Amount] [float] NULL,
	[Gross amount] [float] NULL,
	[TDS Deducted ] [float] NULL,
	[Net Paid Amount] [float] NULL,
	[No of User paid Successful] [float] NULL,
	[Transaction Date's] [datetime] NULL,
	[F12] [nvarchar](255) NULL,
	[F13] [nvarchar](255) NULL
) ON [PRIMARY]
GO
