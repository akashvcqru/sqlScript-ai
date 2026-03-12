/****** Object:  Table [dbo].[NewsLetters]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[NewsLetters](
	[NewsLettersID] [nvarchar](50) NOT NULL,
	[Subject] [nvarchar](550) NULL,
	[Content] [nvarchar](max) NULL,
	[Entry_Date] [datetime] NULL,
	[Status] [tinyint] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
