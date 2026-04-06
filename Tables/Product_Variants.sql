/****** Object:  Table [dbo].[Product_Variants]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Product_Variants](
	[VariantId] [int] IDENTITY(1,1) NOT NULL,
	[ProductCatalogId] [int] NOT NULL,
	[Color] [nvarchar](200) NULL,
	[Size] [nvarchar](200) NULL,
	[IsDelete] [bit] NULL DEFAULT ((0)),
PRIMARY KEY CLUSTERED 
(
	[VariantId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
