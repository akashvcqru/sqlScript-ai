/****** Object:  Table [dbo].[M_CouponCodes]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_CouponCodes](
	[CouponTrans_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Coupon_ID] [nvarchar](50) NULL,
	[CouponCode] [nvarchar](50) NULL,
	[Price] [numeric](18, 0) NULL,
	[ValidFrom] [datetime] NULL,
	[ValidTo] [datetime] NULL,
	[SST_Id] [bigint] NULL,
	[IsUsed] [int] NULL,
	[IsDistributed] [int] NULL,
	[Comp_ID] [nvarchar](50) NULL,
	[AllotedDate] [datetime] NULL,
	[EntryDate] [datetime] NULL,
	[IsCodeUsed] [bit] NULL,
 CONSTRAINT [PK_M_CouponCodes_1] PRIMARY KEY CLUSTERED 
(
	[CouponTrans_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
