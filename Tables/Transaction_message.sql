/****** Object:  Table [dbo].[Transaction_message]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Transaction_message](
	[Message_id] [int] IDENTITY(1,1) NOT NULL,
	[Service_id] [nchar](10) NULL,
	[Message] [nvarchar](max) NOT NULL,
	[pop_message] [nvarchar](max) NULL,
	[scenario] [int] NULL,
	[Manufacturing_date] [date] NULL,
	[Expiry_date] [datetime] NULL,
	[Price] [int] NULL,
	[Comment] [nvarchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
