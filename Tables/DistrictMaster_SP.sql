/****** Object:  Table [dbo].[DistrictMaster_SP]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DistrictMaster_SP](
	[DistrictID] [int] NULL,
	[DistrictName] [varchar](100) NULL,
	[StateID] [int] NULL,
	[IsActive] [int] NULL,
	[IsDelete] [int] NULL
) ON [PRIMARY]
GO
