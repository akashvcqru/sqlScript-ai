/****** Object:  Table [dbo].[PostOffices]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PostOffices](
	[Name] [nvarchar](1000) NULL,
	[Description] [nvarchar](max) NULL,
	[BranchType] [nvarchar](500) NULL,
	[DeliveryStatus] [nvarchar](500) NULL,
	[Circle] [nvarchar](500) NULL,
	[District] [nvarchar](500) NULL,
	[Division] [nvarchar](500) NULL,
	[Region] [nvarchar](500) NULL,
	[Block] [nvarchar](500) NULL,
	[State] [nvarchar](500) NULL,
	[Country] [nvarchar](500) NULL,
	[Pincode] [nvarchar](10) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
