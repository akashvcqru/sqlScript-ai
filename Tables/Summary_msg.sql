/****** Object:  Table [dbo].[Summary_msg]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Summary_msg](
	[msgid] [int] NOT NULL,
	[service_id] [nchar](10) NOT NULL,
	[summary_message] [nvarchar](max) NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
