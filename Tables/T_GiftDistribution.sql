/****** Object:  Table [dbo].[T_GiftDistribution]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_GiftDistribution](
	[Trans_Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Comp_ID] [nvarchar](50) NOT NULL,
	[Pro_ID] [nvarchar](50) NOT NULL,
	[SST_Id] [bigint] NOT NULL,
	[Code1] [numeric](5, 0) NULL,
	[Code2] [numeric](8, 0) NULL,
	[MobileNo] [nvarchar](15) NULL,
	[Prize] [nvarchar](250) NULL,
	[EntryDate] [datetime] NULL,
	[IsUsed] [int] NULL,
	[IsSMS] [int] NULL,
	[IsDelivery] [int] NULL,
	[ReferralCode] [nvarchar](15) NULL,
 CONSTRAINT [PK_T_GiftDistribution] PRIMARY KEY CLUSTERED 
(
	[Trans_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
