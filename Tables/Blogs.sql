/****** Object:  Table [dbo].[Blogs]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Blogs](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Header] [varchar](max) NOT NULL,
	[Post] [varchar](max) NOT NULL,
	[ImagePath] [varchar](max) NULL,
	[CreationDate] [datetime] NOT NULL,
	[VideoPath] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
