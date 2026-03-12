/****** Object:  Table [dbo].[M_CouponTrans]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_CouponTrans](
	[CouponTrans_ID] [bigint] NOT NULL,
	[Coupon_ID] [nvarchar](50) NULL,
	[DateFrom] [datetime] NULL,
	[DateTo] [datetime] NULL,
	[CouponCount] [numeric](18, 0) NULL,
	[AllotedCount] [numeric](18, 0) NULL,
	[IsUsedCount] [numeric](18, 0) NULL,
	[EntryDate] [datetime] NULL,
	[IsActive] [int] NULL,
	[IsDelete] [int] NULL,
 CONSTRAINT [PK_M_CouponTrans] PRIMARY KEY CLUSTERED 
(
	[CouponTrans_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
