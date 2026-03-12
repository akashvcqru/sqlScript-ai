/****** Object:  Table [dbo].[tbl_ab93Code]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_ab93Code](
	[pro_id] [nvarchar](50) NULL,
	[code1] [numeric](5, 0) NOT NULL,
	[code2] [numeric](8, 0) NOT NULL,
	[labelRequestId] [nvarchar](15) NULL,
	[ftext_new] [varchar](54) NULL
) ON [PRIMARY]
GO
