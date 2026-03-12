/****** Object:  Table [dbo].[User_Issue]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[User_Issue](
	[Useid] [nvarchar](50) NOT NULL,
	[Issue] [nvarchar](max) NULL,
	[Entrydate] [datetime] NOT NULL,
	[Code] [numeric](18, 0) NULL,
	[status] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
