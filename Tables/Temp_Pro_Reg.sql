/****** Object:  Table [dbo].[Temp_Pro_Reg]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Temp_Pro_Reg](
	[Row_ID] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[Comp_ID] [nvarchar](50) NULL,
	[Pro_ID] [nvarchar](50) NOT NULL,
	[Pro_Entry_Date] [datetime] NULL,
	[Pro_Name] [nvarchar](50) NULL,
	[Update_Flag] [numeric](18, 0) NULL,
	[Pro_Desc] [varchar](255) NULL,
	[Label_Code] [nvarchar](50) NULL,
	[Pro_Doc] [nvarchar](50) NULL,
	[Doc_Flag] [int] NULL,
	[Sound_Flag] [int] NULL,
	[Update_Flag_H] [numeric](18, 0) NULL,
	[Update_Flag_E] [numeric](18, 0) NULL,
	[Doc_Remark] [varchar](30) NULL,
	[Sound_Remark] [varchar](50) NULL,
	[Remark] [varchar](50) NULL,
	[Comments] [nvarchar](500) NULL,
	[BatchSize] [numeric](18, 0) NULL,
	[Dispatch_Location] [nvarchar](500) NULL
) ON [PRIMARY]
GO
