/****** Object:  Table [dbo].[MMDealerCode]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MMDealerCode](
	[DealerCode] [nvarchar](255) NULL,
	[DealerName] [nvarchar](255) NULL,
	[Location] [nvarchar](255) NULL,
	[District] [nvarchar](255) NULL,
	[AO] [nvarchar](255) NULL,
	[State] [nvarchar](255) NULL,
	[Zone] [nvarchar](255) NULL,
	[CCM] [nvarchar](255) NULL,
	[Category] [nvarchar](255) NULL
) ON [PRIMARY]
GO
