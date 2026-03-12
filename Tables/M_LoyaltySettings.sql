/****** Object:  Table [dbo].[M_LoyaltySettings]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_LoyaltySettings](
	[RowId] [bigint] IDENTITY(1,1) NOT NULL,
	[Comp_ID] [nvarchar](50) NULL,
	[Min_Bank_Transfer] [numeric](18, 0) NULL,
	[Points] [numeric](18, 2) NULL,
	[IsActive] [int] NULL,
	[IsDelete] [int] NULL,
	[Entry_Date] [datetime] NULL,
	[Courier] [int] NULL,
	[Dealer] [int] NULL,
	[PointsAgaintsGift] [int] NULL,
	[MinimumReferralAmountLimit] [int] NULL,
 CONSTRAINT [PK_M_LoyaltySettings] PRIMARY KEY CLUSTERED 
(
	[RowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
