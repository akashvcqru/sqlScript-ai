/****** Object:  Table [dbo].[Mail_Details]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Mail_Details](
	[Row_Id] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[Mail_Type] [nvarchar](50) NULL,
	[Mail_SMTP] [nvarchar](50) NULL,
	[User_Id] [nvarchar](50) NULL,
	[MPassword] [nvarchar](50) NULL
) ON [PRIMARY]
GO
