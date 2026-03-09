/****** Object:  Table [dbo].[M_GiftDisptachDealerCourier]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_GiftDisptachDealerCourier](
	[GiftDispatchid] [bigint] IDENTITY(1,1) NOT NULL,
	[M_Consumerid] [bigint] NULL,
	[M_Gitfid] [int] NULL,
	[DealerOrCourier] [nvarchar](50) NULL,
	[dealeridORcourierid] [int] NULL,
	[dispatchdate] [datetime] NULL,
	[expectdate] [datetime] NULL,
	[CreatedDate] [datetime] NULL,
	[active] [bit] NULL,
	[modifieddate] [datetime] NULL,
	[Comp_Id] [nvarchar](50) NULL,
	[IsCompletedDelivery] [bit] NULL,
	[Status] [int] NULL,
	[M_Consumer_MCodeid] [int] NULL,
	[sst_id] [int] NULL,
	[Servicetype] [nvarchar](50) NULL,
	[TrackingNo] [nvarchar](50) NULL,
 CONSTRAINT [PK_M_GiftDisptachDealerCourier] PRIMARY KEY CLUSTERED 
(
	[GiftDispatchid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
