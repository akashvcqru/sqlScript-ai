/****** Object:  Table [dbo].[NewsLetters_Subscription]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[NewsLetters_Subscription](
	[Row_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Email] [nvarchar](250) NULL,
	[Status] [tinyint] NULL
) ON [PRIMARY]
GO
