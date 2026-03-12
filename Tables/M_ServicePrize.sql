/****** Object:  Table [dbo].[M_ServicePrize]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_ServicePrize](
	[Trans_Id] [bigint] IDENTITY(1,1) NOT NULL,
	[SST_Id] [bigint] NOT NULL,
	[PrizeTrans_Id] [nvarchar](250) NULL,
	[Gift_Id] [nvarchar](250) NULL,
	[GiftName] [nvarchar](250) NULL,
	[GiftCount] [bigint] NULL,
	[DistributeCount] [bigint] NULL,
	[CouponRequest_pkID] [numeric](18, 0) NULL,
 CONSTRAINT [PK_M_ServicePrize] PRIMARY KEY CLUSTERED 
(
	[Trans_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
