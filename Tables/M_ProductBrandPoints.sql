/****** Object:  Table [dbo].[M_ProductBrandPoints]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_ProductBrandPoints](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Comp_ID] [varchar](50) NOT NULL,
	[Pro_ID] [varchar](50) NOT NULL,
	[Brand_Code] [varchar](50) NULL,
	[Points] [numeric](18, 2) NOT NULL,
	[Created_Date] [datetime] NOT NULL,
	[Created_By] [varchar](50) NULL,
	[IsActive] [bit] NOT NULL,
	[Code1] [nvarchar](100) NULL,
	[Code2] [nvarchar](100) NULL,
	[MobileNo] [varchar](20) NULL,
 CONSTRAINT [PK_M_ProductBrandPoints] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
