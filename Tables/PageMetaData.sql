/****** Object:  Table [dbo].[PageMetaData]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PageMetaData](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[PageSlug] [nvarchar](110) NULL,
	[PageName] [nvarchar](100) NULL,
	[Title] [nvarchar](100) NULL,
	[MetaKeywords] [nvarchar](300) NULL,
	[MetaDescription] [nvarchar](400) NULL,
	[CanonicalUrl] [nvarchar](150) NULL,
	[IsActive] [bit] NULL,
	[PageContent] [nvarchar](max) NULL,
	[ImagePath] [nvarchar](300) NULL,
	[CreatedOnUtc] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
