/****** Object:  Table [dbo].[M_Label]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_Label](
	[Row_Id] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[Label_Code] [nvarchar](50) NOT NULL,
	[Label_Name] [nvarchar](50) NOT NULL,
	[Label_Size] [nvarchar](50) NULL,
	[Label_Prise] [numeric](18, 2) NULL,
	[Label_Image] [nvarchar](50) NOT NULL,
	[Entry_Date] [datetime] NULL,
	[Flag] [int] NULL,
 CONSTRAINT [PK_M_Label] PRIMARY KEY CLUSTERED 
(
	[Label_Code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
