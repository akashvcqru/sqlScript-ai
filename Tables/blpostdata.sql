/****** Object:  Table [dbo].[blpostdata]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[blpostdata](
	[Title] [nvarchar](255) NULL,
	[Body] [nvarchar](max) NULL,
	[MetaKeywords] [nvarchar](255) NULL,
	[MetaTitle] [nvarchar](255) NULL,
	[LanguageId] [nvarchar](255) NULL,
	[IncludeInSitemap] [nvarchar](255) NULL,
	[BodyOverview] [nvarchar](255) NULL,
	[AllowComments] [nvarchar](255) NULL,
	[Tags] [nvarchar](255) NULL,
	[StartDateUtc] [datetime] NULL,
	[EndDateUtc] [nvarchar](255) NULL,
	[MetaDescription] [nvarchar](255) NULL,
	[LimitedToStores] [nvarchar](255) NULL,
	[CreatedOnUtc] [datetime] NULL,
	[ImagePath] [nvarchar](255) NULL,
	[Slugs] [nvarchar](255) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
