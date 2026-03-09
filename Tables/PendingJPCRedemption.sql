/****** Object:  Table [dbo].[PendingJPCRedemption]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PendingJPCRedemption](
	[DealerID] [nvarchar](255) NULL,
	[DealerName] [nvarchar](255) NULL,
	[MobileNo] [nvarchar](255) NULL,
	[Amount] [float] NULL,
	[RedemptionDate] [nvarchar](255) NULL
) ON [PRIMARY]
GO
