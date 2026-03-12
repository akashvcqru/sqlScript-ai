/****** Object:  Table [dbo].[Tbl_bannerVcqru]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tbl_bannerVcqru](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ImagePath] [nvarchar](100) NULL,
	[Title] [nvarchar](100) NULL,
	[IsActive] [bit] NULL,
	[compid] [varchar](20) NULL
) ON [PRIMARY]
GO
