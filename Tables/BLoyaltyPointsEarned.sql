/****** Object:  Table [dbo].[BLoyaltyPointsEarned]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BLoyaltyPointsEarned](
	[BLoyalty_PointEarnedID] [bigint] IDENTITY(1,1) NOT NULL,
	[BuildLoyaltyOrReferralMCodeCheckid] [bigint] NULL,
	[SST_id] [bigint] NULL,
	[M_Consumerid] [bigint] NULL,
	[Points] [int] NULL,
	[Cash] [int] NULL,
	[Gift] [nvarchar](50) NULL,
	[UpdateDate] [datetime] NULL,
	[CreatedBy] [int] NULL,
	[ServiceName] [nvarchar](50) NULL,
	[IsEarned] [bit] NULL,
	[IsPointsToGiftOrCashBuildLoyalty] [int] NULL,
	[RedeemDate] [datetime] NULL,
	[TransacionID] [int] NULL,
	[isPointsUsedReferral] [bit] NULL,
	[compid] [nvarchar](100) NULL,
	[Code1] [varchar](5) NULL,
	[Code2] [varchar](8) NULL,
	[refranceM_Consumerid] [int] NULL,
	[isredeem] [int] NULL,
	[points_Updatedate] [datetime] NULL,
	[extraAmount] [decimal](10, 2) NULL,
 CONSTRAINT [PK_BLoyaltyPointsEarned] PRIMARY KEY CLUSTERED 
(
	[BLoyalty_PointEarnedID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
