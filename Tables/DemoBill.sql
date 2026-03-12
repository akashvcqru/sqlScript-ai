/****** Object:  Table [dbo].[DemoBill]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DemoBill](
	[Row_Id] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[Comp_ID] [nvarchar](50) NULL,
	[Current_Bill] [numeric](18, 2) NULL,
	[Previous_Bill] [numeric](18, 2) NULL,
	[Total_Out] [numeric](18, 2) NULL,
	[Remark] [nvarchar](max) NULL,
 CONSTRAINT [PK_DemoBill] PRIMARY KEY CLUSTERED 
(
	[Row_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
