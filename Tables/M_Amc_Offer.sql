/****** Object:  Table [dbo].[M_Amc_Offer]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_Amc_Offer](
	[Amc_Offer_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Comp_ID] [nvarchar](50) NULL,
	[Pro_ID] [nvarchar](50) NULL,
	[Plan_ID] [nvarchar](50) NULL,
	[Plan_Name] [nvarchar](50) NULL,
	[Plan_Amount] [numeric](18, 2) NULL,
	[Date_From] [datetime] NULL,
	[Date_To] [datetime] NULL,
	[Trans_Type] [nvarchar](50) NULL,
	[Status] [numeric](18, 0) NULL,
	[Plan_Discount] [numeric](18, 2) NULL,
	[IsCancel] [int] NULL,
	[Entry_Date] [datetime] NULL,
	[Update_Flag_H] [numeric](18, 0) NULL,
	[Update_Flag_E] [numeric](18, 0) NULL,
	[Comments] [nvarchar](100) NULL
) ON [PRIMARY]
GO
