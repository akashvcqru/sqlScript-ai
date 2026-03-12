/****** Object:  Table [dbo].[tPrint_arb1]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tPrint_arb1](
	[pro_id] [nvarchar](50) NULL,
	[code1] [numeric](5, 0) NULL,
	[code2] [numeric](8, 0) NULL,
	[id] [varchar](max) NULL,
	[id1] [varchar](max) NOT NULL,
	[fText] [varchar](max) NOT NULL,
	[Id_new] [int] IDENTITY(1,1) NOT NULL,
	[fText_New] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
