/****** Object:  Table [dbo].[tbl_event_bk]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_event_bk](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[imgpath] [varchar](500) NULL,
	[galerry_id] [int] NULL,
	[event_name] [nvarchar](150) NULL,
	[event_content] [varchar](max) NULL,
	[event_date] [nchar](10) NULL,
	[created_date] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
