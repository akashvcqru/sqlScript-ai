/****** Object:  Table [dbo].[tbl_Postransactiondetails]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_Postransactiondetails](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Mobileno] [nvarchar](100) NULL,
	[ConsumerName] [nvarchar](100) NULL,
	[VehicleNumber] [nvarchar](50) NULL,
	[VolumeInLitres] [decimal](10, 2) NULL,
	[Rateofcalculation] [decimal](10, 2) NULL,
	[TotalPoints] [decimal](10, 2) NULL,
	[PosTransactionId] [nvarchar](100) NULL,
	[OutletCode] [nvarchar](50) NULL,
	[TimeOfTransaction] [datetime] NULL,
	[Code1] [int] NULL,
	[code2] [int] NULL,
	[URL] [nvarchar](500) NULL,
	[Comp_id] [nvarchar](100) NULL,
	[IsRedeemed] [bit] NULL,
	[CreatedAt] [datetime] NULL,
	[RedeemAt] [datetime] NULL,
	[Remarks] [nvarchar](500) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
