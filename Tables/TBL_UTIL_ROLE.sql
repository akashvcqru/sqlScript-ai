/****** Object:  Table [dbo].[TBL_UTIL_ROLE]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TBL_UTIL_ROLE](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ROLE] [varchar](100) NULL,
	[ROLE_DESCRIPTION] [varchar](max) NULL,
	[NOTE] [varchar](max) NULL,
	[CREATED_BY] [int] NULL,
	[CREATED_ON] [datetime] NULL,
	[UPDATED_BY] [int] NULL,
	[UPDATED_ON] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
