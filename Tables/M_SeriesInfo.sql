/****** Object:  Table [dbo].[M_SeriesInfo]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_SeriesInfo](
	[Row_ID] [int] IDENTITY(1,1) NOT NULL,
	[Comp_ID] [nvarchar](50) NULL,
	[Pro_ID] [nvarchar](50) NULL,
	[Series] [numeric](18, 0) NULL,
	[Order] [numeric](18, 0) NULL,
	[EntryDate] [datetime] NULL
) ON [PRIMARY]
GO
