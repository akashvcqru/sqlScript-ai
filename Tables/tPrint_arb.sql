/****** Object:  Table [dbo].[tPrint_arb]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tPrint_arb](
	[pro_id] [nvarchar](50) NULL,
	[code1] [numeric](5, 0) NULL,
	[code2] [numeric](8, 0) NULL,
	[id] [varchar](38) NULL,
	[id1] [varchar](1) NOT NULL,
	[fText] [varchar](1) NOT NULL
) ON [PRIMARY]
GO
