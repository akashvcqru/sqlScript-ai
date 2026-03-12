/****** Object:  Table [dbo].[TBLAppVersionHistory]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TBLAppVersionHistory](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[VID] [int] NULL,
	[AppName] [varchar](50) NULL,
	[Appversion] [varchar](20) NULL,
	[ReqDate] [datetime] NULL,
	[Status] [varchar](10) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
