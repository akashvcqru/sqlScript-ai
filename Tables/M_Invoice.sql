/****** Object:  Table [dbo].[M_Invoice]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_Invoice](
	[Row_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Invoice_ID] [nvarchar](50) NULL,
	[Invoice_Date] [datetime] NULL,
	[Comp_ID] [nvarchar](50) NULL,
	[Pro_ID] [nvarchar](50) NULL,
	[Head_ID] [nvarchar](50) NULL,
	[Head_Name] [nvarchar](50) NULL,
	[G_Amount] [numeric](18, 2) NULL,
	[Discount] [numeric](18, 2) NULL,
	[Service_Tax] [numeric](18, 2) NULL,
	[VAT] [numeric](18, 2) NULL,
	[N_Amount] [numeric](18, 2) NULL,
	[Refund_From] [nvarchar](50) NULL,
	[Upgrade_From] [nvarchar](500) NULL,
	[Upgrade_Amount] [numeric](18, 2) NULL,
	[Last_Payment_Receipt] [nvarchar](50) NULL,
	[Last_Paid_Amount] [numeric](18, 2) NULL,
	[Last_Paid_Date] [datetime] NULL,
	[Balance] [numeric](18, 2) NULL,
	[Net_Pay] [numeric](18, 2) NULL,
	[Status] [int] NULL
) ON [PRIMARY]
GO
