/****** Object:  Table [dbo].[IFSC]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[IFSC](
	[BANK] [nvarchar](255) NULL,
	[IFSC] [nvarchar](255) NULL,
	[BRANCH] [nvarchar](255) NULL,
	[ADDRESS] [nvarchar](255) NULL,
	[CONTACT] [float] NULL,
	[CITY] [nvarchar](255) NULL,
	[DISTRICT] [nvarchar](255) NULL,
	[STATE] [nvarchar](255) NULL,
	[STD CODE] [float] NULL
) ON [PRIMARY]
GO
