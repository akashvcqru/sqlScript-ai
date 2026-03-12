/****** Object:  Table [dbo].[M_PrintTrans]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_PrintTrans](
	[Row_ID] [numeric](12, 0) IDENTITY(1,1) NOT NULL,
	[Trans_ID] [numeric](12, 0) NULL,
	[Pro_ID] [nvarchar](8) NULL,
	[SeriesOrder] [numeric](18, 0) NULL,
	[SeriesFrom] [numeric](18, 0) NULL,
	[SeriesTo] [numeric](18, 0) NULL,
 CONSTRAINT [PK__M_PrintTrans_Row_ID] PRIMARY KEY CLUSTERED 
(
	[Row_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
