/****** Object:  Table [dbo].[JPCRedemptionDec]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[JPCRedemptionDec](
	[Date] [datetime] NULL,
	[Particulars] [nvarchar](255) NULL,
	[Mobile No] [nvarchar](255) NULL,
	[Dealer ID] [nvarchar](255) NULL,
	[Vch Type] [nvarchar](255) NULL,
	[Debit] [float] NULL
) ON [PRIMARY]
GO
