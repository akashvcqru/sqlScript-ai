/****** Object:  Table [dbo].[MultiAccountDetails]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MultiAccountDetails](
	[MobileNo] [numeric](18, 0) NULL,
	[TotalCount] [float] NULL,
	[Entry_Date] [datetime] NULL,
	[UsedInCodeCheck] [nvarchar](255) NULL
) ON [PRIMARY]
GO
