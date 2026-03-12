/****** Object:  Table [dbo].[M_ServiceFeature]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_ServiceFeature](
	[ServiceFeaure_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Service_ID] [nvarchar](10) NOT NULL,
	[IsPoints] [numeric](10, 0) NULL,
	[IsCash] [numeric](10, 0) NULL,
	[IsDateRange] [int] NULL,
	[IsSound] [int] NULL,
	[IsFrequency] [int] NULL,
	[IsAdditionalGift] [int] NULL,
	[IsCoupons] [int] NULL,
	[IsMessageTemplete] [int] NULL,
	[IsNotify] [int] NULL,
	[IsNoMessage] [int] NULL,
	[IsReferral] [int] NULL,
	[IsRandom] [int] NULL,
	[EntryDate] [datetime] NULL,
	[IsDelete] [int] NULL,
	[IsWarranty] [int] NULL,
 CONSTRAINT [PK_M_ServiceFeature] PRIMARY KEY CLUSTERED 
(
	[ServiceFeaure_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
