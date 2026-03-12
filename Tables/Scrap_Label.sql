/****** Object:  Table [dbo].[Scrap_Label]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Scrap_Label](
	[Row_Id] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[Comp_ID] [nvarchar](50) NULL,
	[Pro_ID] [nvarchar](50) NULL,
	[Batch_No] [nvarchar](50) NULL,
	[Serial_Code] [nvarchar](max) NULL,
	[Entry_Date] [datetime] NULL,
	[To_Serial_Code] [nvarchar](max) NULL,
	[Type] [int] NULL,
	[scrapedby] [nvarchar](13) NULL,
	[M_codeid] [int] NULL,
	[Remarks] [nvarchar](500) NULL,
 CONSTRAINT [PK_Scrap_Label] PRIMARY KEY CLUSTERED 
(
	[Row_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
