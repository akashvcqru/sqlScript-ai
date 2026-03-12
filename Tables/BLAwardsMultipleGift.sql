/****** Object:  Table [dbo].[BLAwardsMultipleGift]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BLAwardsMultipleGift](
	[BlAwardsMultipleGiftid] [int] IDENTITY(1,1) NOT NULL,
	[BLAwardsid] [int] NULL,
	[Giftid] [int] NULL,
	[CreatedDate] [datetime] NULL,
	[Createdby] [nvarchar](50) NULL,
 CONSTRAINT [PK_BLAwardsMultipleGift] PRIMARY KEY CLUSTERED 
(
	[BlAwardsMultipleGiftid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
