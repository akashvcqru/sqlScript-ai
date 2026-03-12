/****** Object:  Table [dbo].[NoofItemCartoon]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[NoofItemCartoon](
	[NoofItemsPerCartoonid] [int] IDENTITY(1,1) NOT NULL,
	[compid] [nvarchar](50) NULL,
	[NoofItemsPerCartoon] [int] NULL,
 CONSTRAINT [PK_NoofItemCartoon] PRIMARY KEY CLUSTERED 
(
	[NoofItemsPerCartoonid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
