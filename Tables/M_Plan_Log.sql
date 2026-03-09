/****** Object:  Table [dbo].[M_Plan_Log]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_Plan_Log](
	[Row_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Plan_ID] [nvarchar](50) NULL,
	[Plan_Name] [nvarchar](50) NULL,
	[Plan_Time] [numeric](18, 0) NULL,
	[Plan_Amount] [numeric](18, 2) NULL,
	[Entry_Date] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[Row_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
