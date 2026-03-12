/****** Object:  Table [dbo].[M_Generate_Bill]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_Generate_Bill](
	[Row_Id] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[Invoice_No] [nvarchar](50) NOT NULL,
	[Comp_ID] [nvarchar](50) NULL,
	[Generate_Date] [datetime] NULL,
	[G_Amount] [numeric](18, 2) NULL,
	[Tax] [numeric](18, 2) NULL,
	[N_Amount] [numeric](18, 2) NULL,
	[Pre_Bal] [numeric](18, 2) NULL,
	[Trans_Type] [nvarchar](50) NULL,
 CONSTRAINT [PK_M_Generate_Bill] PRIMARY KEY CLUSTERED 
(
	[Invoice_No] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
