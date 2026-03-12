/****** Object:  Table [dbo].[Products_catalog_Details]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Products_catalog_Details](
	[Row_Id] [int] IDENTITY(1,1) NOT NULL,
	[CategoryId] [int] NULL,
	[ProductDescription] [nvarchar](max) NULL,
	[Point] [varchar](500) NULL,
	[Price] [decimal](18, 2) NULL,
	[StockQuantity] [nvarchar](100) NULL,
	[ImagePath] [nvarchar](max) NULL,
	[Comp_id] [nvarchar](50) NULL,
	[Isactive] [bit] NOT NULL,
	[Isdelete] [bit] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[Remarks] [nvarchar](max) NULL,
	[IsSalable] [bit] NULL,
	[DiscountPrice] [decimal](10, 2) NULL,
	[IsVariable] [bit] NULL,
	[ProductName] [nvarchar](max) NULL,
	[SubCategory] [varchar](100) NULL,
	[ImagePath2] [nvarchar](max) NULL,
	[ImagePath3] [nvarchar](max) NULL,
	[ImagePath4] [nvarchar](max) NULL,
	[ImagePath5] [nvarchar](max) NULL,
PRIMARY KEY CLUSTERED 
(
	[Row_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
