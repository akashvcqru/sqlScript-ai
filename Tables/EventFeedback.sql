/****** Object:  Table [dbo].[EventFeedback]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EventFeedback](
	[ConsumerName] [nvarchar](150) NULL,
	[MobileNo] [nvarchar](15) NULL,
	[Suggestion] [varchar](500) NULL,
	[Rating] [char](1) NULL,
	[Date] [datetime] NULL,
	[Interacted Persion] [varchar](100) NULL
) ON [PRIMARY]
GO
