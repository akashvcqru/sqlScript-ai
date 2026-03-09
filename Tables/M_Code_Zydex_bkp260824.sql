/****** Object:  Table [dbo].[M_Code_Zydex_bkp260824]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_Code_Zydex_bkp260824](
	[Row_ID] [numeric](12, 0) IDENTITY(1,1) NOT NULL,
	[Code1] [numeric](5, 0) NOT NULL,
	[Code2] [numeric](8, 0) NOT NULL,
	[Pro_ID] [nvarchar](50) NULL,
	[M_Codeid] [int] NOT NULL,
	[Distributor_ID] [varchar](50) NOT NULL,
	[Bill_Date] [datetime] NULL,
	[Map_Date] [datetime] NULL,
	[Serial_Number] [int] NOT NULL,
	[Company_ID] [varchar](20) NULL,
	[Created_Date] [datetime] NULL,
	[Created_By] [varchar](50) NULL,
	[Updated_Date] [datetime] NULL,
	[Updated_By] [varchar](50) NULL,
	[Remarks] [varchar](255) NULL,
	[Batch_Number] [varchar](100) NULL
) ON [PRIMARY]
GO
