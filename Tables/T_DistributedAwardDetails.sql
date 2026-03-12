/****** Object:  Table [dbo].[T_DistributedAwardDetails]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_DistributedAwardDetails](
	[RowId] [bigint] IDENTITY(1,1) NOT NULL,
	[User_ID] [nvarchar](50) NULL,
	[Comp_ID] [nvarchar](50) NULL,
	[Dealer_ID] [nvarchar](50) NULL,
	[TransactionNo] [nvarchar](50) NULL,
	[Delivery_Type] [nvarchar](50) NULL,
	[IsDelivered] [int] NULL,
	[Remarks] [nvarchar](500) NULL,
	[Cash_Amount] [numeric](18, 0) NULL,
	[Entry_Date] [datetime] NULL,
	[Award_Key] [nvarchar](10) NULL,
	[IsDispatch] [int] NULL
) ON [PRIMARY]
GO
