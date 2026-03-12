/****** Object:  Table [dbo].[Tbl_MenuMaster]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tbl_MenuMaster](
	[MenuMaster_Id] [int] IDENTITY(1,1) NOT NULL,
	[MenuName] [nvarchar](150) NOT NULL,
	[Icon] [nvarchar](200) NULL,
	[Path] [nvarchar](300) NULL,
	[ParentId] [int] NULL,
	[Service] [nvarchar](10) NOT NULL,
	[MenuSection] [nvarchar](20) NOT NULL,
	[SortOrder] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedAt] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[MenuMaster_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
