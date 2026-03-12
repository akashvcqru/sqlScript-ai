/****** Object:  Table [dbo].[M_Coupon]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_Coupon](
	[Coupon_ID] [nvarchar](50) NOT NULL,
	[CouponName] [nvarchar](150) NULL,
	[CouponProvider_Id] [bigint] NOT NULL,
	[EntryDate] [datetime] NULL,
	[IsActive] [int] NULL,
	[IsDelete] [int] NULL,
 CONSTRAINT [PK_M_Coupon] PRIMARY KEY CLUSTERED 
(
	[Coupon_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
