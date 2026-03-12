/****** Object:  Table [dbo].[Customer_Care]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Customer_Care](
	[Row_Id] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[Customer_Id] [nvarchar](50) NULL,
	[Customer_Name] [nvarchar](50) NULL,
	[Mobile_No] [nvarchar](50) NULL,
	[Email] [nvarchar](50) NULL,
	[Address] [nvarchar](max) NULL,
	[Password] [nvarchar](50) NULL,
	[Status] [numeric](18, 0) NULL,
	[User_Type] [nvarchar](50) NULL,
	[Entry_Date] [nvarchar](50) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
