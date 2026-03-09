/****** Object:  Table [dbo].[tblProducts_catalog_Details]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblProducts_catalog_Details](
	[Row_Id] [int] IDENTITY(1,1) NOT NULL,
	[ProductId] [int] NULL,
	[ProductDescription] [nvarchar](max) NULL,
	[Point] [varchar](500) NULL,
	[Price] [nvarchar](100) NULL,
	[StockQuantity] [nvarchar](100) NULL,
	[ImagePath] [nvarchar](max) NULL,
	[Comp_id] [nvarchar](50) NULL,
	[Isactive] [bit] NULL,
	[Isdelete] [bit] NULL,
	[CreatedDate] [datetime] NULL,
	[Remarks] [nvarchar](max) NULL,
PRIMARY KEY CLUSTERED 
(
	[Row_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
