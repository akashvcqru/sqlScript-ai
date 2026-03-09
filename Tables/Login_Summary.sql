/****** Object:  Table [dbo].[Login_Summary]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Login_Summary](
	[Row_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[User_ID] [nvarchar](50) NULL,
	[Login_Date] [datetime] NULL,
	[Logout_Date] [datetime] NULL,
	[User_Type] [int] NULL
) ON [PRIMARY]
GO
