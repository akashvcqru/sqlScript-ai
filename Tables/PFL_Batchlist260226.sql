/****** Object:  Table [dbo].[PFL_Batchlist260226]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PFL_Batchlist260226](
	[Date Of Mfg] [datetime] NULL,
	[Expire Date] [datetime] NULL,
	[SKU] [nvarchar](255) NULL,
	[Batch No] [nvarchar](255) NULL,
	[From] [nvarchar](255) NULL,
	[To] [nvarchar](255) NULL,
	[Total Use] [float] NULL,
	[Actual Spool Qty] [float] NULL,
	[Bal Qty] [float] NULL,
	[Diff QR V Prd] [nvarchar](255) NULL,
	[Remarks] [nvarchar](255) NULL,
	[RequestDate] [datetime] NULL,
	[Assigned By] [nvarchar](100) NULL
) ON [PRIMARY]
GO
