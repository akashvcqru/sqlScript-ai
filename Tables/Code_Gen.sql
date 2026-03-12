/****** Object:  Table [dbo].[Code_Gen]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Code_Gen](
	[id] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[Prfor] [nvarchar](50) NULL,
	[PrPrefix] [nvarchar](50) NULL,
	[PrStart] [numeric](18, 0) NULL,
	[PrFlag] [numeric](18, 0) NULL,
 CONSTRAINT [PK_Code_Gen] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
