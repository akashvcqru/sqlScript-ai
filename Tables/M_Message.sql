/****** Object:  Table [dbo].[M_Message]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_Message](
	[Row_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Send_To] [nvarchar](250) NULL,
	[Send_CC] [nvarchar](250) NULL,
	[Send_BCC] [nvarchar](250) NULL,
	[Subject] [nvarchar](max) NULL,
	[Message] [nvarchar](max) NULL,
	[Entry_Date] [datetime] NULL,
	[Filename] [nvarchar](500) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
