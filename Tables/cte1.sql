/****** Object:  Table [dbo].[cte1]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[cte1](
	[Code1] [numeric](5, 0) NOT NULL,
	[Code2] [numeric](8, 0) NOT NULL,
	[Pro_ID] [nvarchar](50) NULL,
	[Comp_ID] [nvarchar](50) NOT NULL,
	[Comp_Name] [nvarchar](50) NULL
) ON [PRIMARY]
GO
