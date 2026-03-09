/****** Object:  Table [dbo].[T_LabelPriseLog]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_LabelPriseLog](
	[Row_Id] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[Label_Code] [nvarchar](50) NOT NULL,
	[Label_Prise] [numeric](18, 2) NULL,
	[Entry_Date] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[Row_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
