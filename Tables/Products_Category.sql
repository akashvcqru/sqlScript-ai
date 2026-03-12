/****** Object:  Table [dbo].[Products_Category]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Products_Category](
	[CategoryId] [int] IDENTITY(1,1) NOT NULL,
	[CategoryName] [nvarchar](500) NULL,
	[CategoryDescription] [nvarchar](max) NULL,
	[Point] [varchar](500) NULL,
	[Price] [nvarchar](100) NULL,
	[StockQuantity] [nvarchar](100) NULL,
	[ImagePath] [nvarchar](max) NULL,
	[Comp_id] [nvarchar](50) NULL,
	[Isactive] [bit] NOT NULL,
	[Isdelete] [bit] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[Remarks] [nvarchar](max) NULL,
PRIMARY KEY CLUSTERED 
(
	[CategoryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
