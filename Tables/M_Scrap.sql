/****** Object:  Table [dbo].[M_Scrap]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_Scrap](
	[Row_Id] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[Scrap_ID] [nvarchar](50) NULL,
	[Pro_ID] [nvarchar](50) NULL,
	[Resion_ID] [int] NULL,
	[Scrap_Details] [nvarchar](max) NULL,
	[Remarks] [nvarchar](max) NULL,
	[Entry_Date] [datetime] NULL,
 CONSTRAINT [PK__M_Scrap__6FB49575] PRIMARY KEY CLUSTERED 
(
	[Row_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
