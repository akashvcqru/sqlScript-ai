/****** Object:  Table [dbo].[OCIStatusUpdate]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OCIStatusUpdate](
	[Claim ID] [float] NULL,
	[Claim Date] [datetime] NULL,
	[Mobile No] [nvarchar](255) NULL,
	[Points] [float] NULL,
	[Gifts_Redeemed] [nvarchar](255) NULL,
	[ConsumerName] [nvarchar](255) NULL,
	[City] [nvarchar](255) NULL,
	[Documents Status] [nvarchar](255) NULL,
	[Vendor Comment] [nvarchar](255) NULL,
	[Claim Status] [nvarchar](255) NULL,
	[Action Date] [datetime] NULL,
	[UserType] [nvarchar](255) NULL
) ON [PRIMARY]
GO
