/****** Object:  Table [dbo].[tblappnotification]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblappnotification](
	[Message_id] [int] IDENTITY(1,1) NOT NULL,
	[Compid] [varchar](20) NULL,
	[Mobile] [varchar](20) NULL,
	[Headers] [nvarchar](255) NULL,
	[Message] [nvarchar](max) NULL,
	[Valid_from] [date] NULL,
	[Valid_till] [date] NULL,
	[Image_Path] [nvarchar](255) NULL,
	[IsActive] [int] NULL,
	[Created_Date] [datetime] NULL,
	[notiType] [nvarchar](1000) NULL,
	[IsRead] [bit] NOT NULL,
	[IsReadTimpStamp] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[Message_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [c]
GO
