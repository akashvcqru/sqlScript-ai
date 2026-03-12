/****** Object:  Table [dbo].[Tbl_notificationmaster]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tbl_notificationmaster](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[comp_id] [nvarchar](20) NOT NULL,
	[title] [nvarchar](255) NOT NULL,
	[status] [nvarchar](255) NOT NULL,
	[messgae] [nvarchar](max) NOT NULL,
	[Isactive] [bit] NULL,
	[created_at] [datetime] NOT NULL,
	[notiType] [varchar](50) NULL,
	[KycCat] [varchar](150) NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
