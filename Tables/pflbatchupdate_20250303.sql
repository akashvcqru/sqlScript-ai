/****** Object:  Table [dbo].[pflbatchupdate_20250303]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[pflbatchupdate_20250303](
	[Row_ID] [numeric](12, 0) IDENTITY(1,1) NOT NULL,
	[Gen_Date] [datetime] NULL,
	[Gen_By] [char](5) NULL,
	[Code1] [numeric](5, 0) NOT NULL,
	[Code2] [numeric](8, 0) NOT NULL,
	[Use_Type] [char](7) NULL,
	[Allot_Date] [datetime] NULL,
	[Pro_ID] [nvarchar](50) NULL,
	[Print_Status] [tinyint] NULL,
	[Print_Date] [datetime] NULL,
	[Batch_No] [nvarchar](50) NULL,
	[Use_Count] [numeric](5, 0) NULL,
	[Series_Order] [numeric](10, 0) NULL,
	[Series_Serial] [numeric](4, 0) NULL,
	[ScrapeFlag] [tinyint] NULL,
	[DispatchFlag] [tinyint] NULL,
	[ReceiveFlag] [tinyint] NULL,
	[LabelRequestId] [nvarchar](15) NULL,
	[IsCouponUsed] [bit] NULL,
	[QRCodeStatus] [bit] NULL
) ON [PRIMARY]
GO
