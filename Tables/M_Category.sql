/****** Object:  Table [dbo].[M_Category]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_Category](
	[Row_Id] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[Cat_Id] [numeric](18, 0) NULL,
	[Cat_Name] [nvarchar](50) NULL
) ON [PRIMARY]
GO
