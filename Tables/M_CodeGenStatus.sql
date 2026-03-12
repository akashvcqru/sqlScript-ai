/****** Object:  Table [dbo].[M_CodeGenStatus]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_CodeGenStatus](
	[Row_ID] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[Gen_Date] [datetime] NULL,
	[NoOfCode] [nvarchar](50) NULL,
	[GenCode] [nvarchar](50) NOT NULL,
	[OldGenCode] [nvarchar](50) NOT NULL,
	[Status] [nvarchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[Row_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
