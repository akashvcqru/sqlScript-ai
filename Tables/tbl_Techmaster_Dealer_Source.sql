/****** Object:  Table [dbo].[tbl_Techmaster_Dealer_Source]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_Techmaster_Dealer_Source](
	[SNo] [float] NULL,
	[TechmasterId] [float] NULL,
	[DealerCode] [nvarchar](255) NULL,
	[Zone] [nvarchar](255) NULL,
	[DState] [nvarchar](255) NULL,
	[Category] [nvarchar](255) NULL
) ON [PRIMARY]
GO
