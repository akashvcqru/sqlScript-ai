/****** Object:  Table [dbo].[tblAssignedArtImages]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblAssignedArtImages](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[M_CodeId] [int] NULL,
	[ArtImageId] [int] NULL,
	[ReqDate] [datetime] NULL,
	[Code1] [numeric](18, 0) NULL,
	[Code2] [numeric](18, 0) NULL,
	[ImagePath] [varchar](255) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
