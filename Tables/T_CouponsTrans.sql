/****** Object:  Table [dbo].[T_CouponsTrans]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_CouponsTrans](
	[Trans_Id] [bigint] IDENTITY(1,1) NOT NULL,
	[SST_Id] [bigint] NOT NULL,
	[PointsReferral] [numeric](18, 0) NULL,
	[PointsUsers] [numeric](18, 0) NULL,
	[IsCashReferral] [numeric](18, 0) NULL,
	[IsCashUsers] [numeric](18, 0) NULL,
	[IsCashConvert] [int] NULL,
	[GiftReferral] [nvarchar](150) NULL,
	[GiftUsers] [nvarchar](150) NULL,
	[Frequency] [int] NULL,
	[Typeofgift] [nvarchar](50) NULL,
 CONSTRAINT [PK_T_CouponsTrans] PRIMARY KEY CLUSTERED 
(
	[Trans_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
