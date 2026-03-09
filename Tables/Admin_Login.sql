/****** Object:  Table [dbo].[Admin_Login]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Admin_Login](
	[Row_Id] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[User_Id] [nvarchar](50) NULL,
	[Password] [nvarchar](50) NULL,
	[Status] [numeric](18, 0) NULL,
	[User_Type] [nvarchar](50) NULL
) ON [PRIMARY]
GO
