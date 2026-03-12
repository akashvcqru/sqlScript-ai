/****** Object:  Table [dbo].[Login_History]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Login_History](
	[Row_ID] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[Dial_Mode] [nvarchar](50) NULL,
	[User_ID] [nvarchar](50) NULL,
	[Login_Date] [datetime] NULL,
	[Logout_Date] [datetime] NULL,
	[User_Type] [int] NULL
) ON [PRIMARY]
GO
