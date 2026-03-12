/****** Object:  Table [dbo].[BPointsTransaction]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BPointsTransaction](
	[BPointsTransactionid] [int] IDENTITY(1,1) NOT NULL,
	[Transsctionid] [int] NULL,
	[TotalPoints] [decimal](18, 3) NULL,
	[RedeemPoints] [decimal](18, 3) NULL,
	[Redeemdate] [datetime] NULL,
	[RedeemBy] [int] NULL,
	[IsRedeemOnPurchase] [bit] NULL,
	[NextBillNo] [nvarchar](50) NULL,
	[Incash] [decimal](18, 3) NULL,
	[PointAdjustStatus] [int] NULL,
	[NextBillAdjustDate] [datetime] NULL,
	[NextBillingAmount] [float] NULL,
	[bpstatus] [varchar](15) NULL,
	[companyid] [nvarchar](20) NULL,
	[UPI ID] [varchar](100) NULL,
	[Transaction_Number] [varchar](100) NULL
) ON [PRIMARY]
GO
