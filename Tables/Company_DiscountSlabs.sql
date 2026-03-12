/****** Object:  Table [dbo].[Company_DiscountSlabs]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Company_DiscountSlabs](
	[DiscountSlabId] [int] IDENTITY(1,1) NOT NULL,
	[Comp_Id] [nvarchar](50) NOT NULL,
	[DiscountPercent] [decimal](5, 2) NOT NULL,
	[OnTotalAmount] [decimal](18, 2) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[DiscountSlabId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
