/****** Object:  Table [dbo].[BlogPost]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BlogPost](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Title] [nvarchar](max) NOT NULL,
	[Body] [nvarchar](max) NOT NULL,
	[MetaKeywords] [nvarchar](400) NULL,
	[MetaTitle] [nvarchar](400) NULL,
	[LanguageId] [int] NULL,
	[IncludeInSitemap] [bit] NULL,
	[BodyOverview] [nvarchar](max) NULL,
	[AllowComments] [bit] NULL,
	[Tags] [nvarchar](max) NULL,
	[StartDateUtc] [datetime2](7) NULL,
	[EndDateUtc] [datetime2](7) NULL,
	[MetaDescription] [nvarchar](max) NULL,
	[LimitedToStores] [bit] NULL,
	[CreatedOnUtc] [datetime2](7) NOT NULL,
	[ImagePath] [varchar](max) NULL,
	[Slugs] [varchar](500) NULL,
 CONSTRAINT [PK_BlogPost] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
