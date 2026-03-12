/****** Object:  Table [dbo].[T_probkp]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_probkp](
	[Row_ID] [numeric](10, 0) IDENTITY(1,1) NOT NULL,
	[Pro_ID] [char](5) NULL,
	[MRP] [numeric](10, 2) NULL,
	[Mfd_Date] [datetime] NULL,
	[Exp_Date] [datetime] NULL,
	[Batch_No] [nvarchar](50) NULL,
	[Entry_Date] [datetime] NULL,
	[Update_Flag_H] [tinyint] NULL,
	[Update_Flag_E] [tinyint] NULL,
	[Series_Limit] [nvarchar](500) NULL,
	[Comments] [nvarchar](100) NULL,
	[IsWarranty] [bit] NULL,
	[WarrantyDurationMonth] [int] NULL
) ON [PRIMARY]
GO
