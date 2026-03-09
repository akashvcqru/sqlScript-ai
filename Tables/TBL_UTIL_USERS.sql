/****** Object:  Table [dbo].[TBL_UTIL_USERS]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TBL_UTIL_USERS](
	[ID] [int] IDENTITY(10,1) NOT NULL,
	[USER_NAME] [varchar](50) NULL,
	[USER_ADDRESS] [varchar](150) NULL,
	[USER_MAIL] [varchar](30) NULL,
	[USER_PASSWORD] [varchar](60) NULL,
	[USER_EMPID] [varchar](50) NULL,
	[USER_ROLE_ID] [int] NULL,
	[USER_NOTES] [varchar](max) NULL,
	[CREATED_BY] [int] NULL,
	[CREATED_DATE] [datetime] NULL,
	[UPDATED_BY] [int] NULL,
	[UPDATED_DATE] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
