/****** Object:  Table [dbo].[M_ServiceGiftTrans]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_ServiceGiftTrans](
	[Row_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[GiftTransGroupID] [bigint] NULL,
	[SST_Id] [bigint] NULL,
	[Gift_ID] [bigint] NULL,
	[GiftCount] [numeric](18, 0) NULL,
	[LuckyNoCount] [numeric](18, 0) NULL,
 CONSTRAINT [PK_M_ServiceGiftTrans] PRIMARY KEY CLUSTERED 
(
	[Row_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
