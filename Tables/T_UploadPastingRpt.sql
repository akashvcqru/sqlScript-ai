/****** Object:  Table [dbo].[T_UploadPastingRpt]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_UploadPastingRpt](
	[Row_ID] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[File_ID] [nvarchar](50) NULL,
	[Comp_ID] [nvarchar](50) NULL,
	[Pro_ID] [nvarchar](50) NULL,
	[Batch_No] [nvarchar](50) NULL,
	[FilePath] [nvarchar](500) NULL,
	[Entry_Date] [datetime] NULL,
	[Flag] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[Row_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
