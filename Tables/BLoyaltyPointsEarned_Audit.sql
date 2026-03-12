/****** Object:  Table [dbo].[BLoyaltyPointsEarned_Audit]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BLoyaltyPointsEarned_Audit](
	[LoyaltyPointsAuditID] [int] IDENTITY(1,1) NOT NULL,
	[BuildLoyaltyOrReferralMCodeCheckid] [bigint] NULL,
	[SST_id] [bigint] NULL,
	[M_Consumerid] [bigint] NULL,
	[Points] [int] NULL,
	[Cash] [int] NULL,
	[Gift] [nvarchar](100) NULL,
	[CreatedBy] [nvarchar](128) NULL,
	[CreatedOn] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[LoyaltyPointsAuditID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
