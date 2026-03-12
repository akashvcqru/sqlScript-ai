/****** Object:  Table [dbo].[AmbicaManualPayout]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AmbicaManualPayout](
	[TotalPoints] [float] NULL,
	[RedeemPoints] [float] NULL,
	[Redeemdate] [datetime] NULL,
	[RedeemBy] [nvarchar](255) NULL,
	[IsRedeemOnPurchase] [nvarchar](255) NULL,
	[NextBillNo] [nvarchar](255) NULL,
	[Incash] [nvarchar](255) NULL,
	[PointAdjustStatus] [nvarchar](255) NULL,
	[NextBillAdjustDate] [nvarchar](255) NULL,
	[NextBillingAmount] [nvarchar](255) NULL,
	[bpstatus] [nvarchar](255) NULL,
	[companyid] [nvarchar](255) NULL,
	[UPI ID] [nvarchar](255) NULL,
	[Transaction_Number] [float] NULL,
	[Transaction_Number1] [nvarchar](255) NULL,
	[Mobile_Number] [float] NULL,
	[Mobile_Number1] [nvarchar](255) NULL,
	[modeofenq] [nvarchar](255) NULL,
	[Completecode] [float] NULL,
	[Code1] [nvarchar](255) NULL,
	[Code2] [nvarchar](255) NULL,
	[ConsumerName] [nvarchar](255) NULL,
	[enq_date] [datetime] NULL,
	[Status ] [nvarchar](255) NULL
) ON [PRIMARY]
GO
