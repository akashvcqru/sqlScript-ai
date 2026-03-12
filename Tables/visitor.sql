/****** Object:  Table [dbo].[visitor]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[visitor](
	[City] [nchar](50) NULL,
	[Region] [nvarchar](50) NULL,
	[Country] [nchar](50) NULL,
	[Country_code] [nvarchar](10) NULL,
	[LoginTime] [datetime] NULL,
	[Ip_address] [nvarchar](max) NULL,
	[zipcode] [nvarchar](50) NULL,
	[lattitude] [nvarchar](max) NULL,
	[longitude] [nvarchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
