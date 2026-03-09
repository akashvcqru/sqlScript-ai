/****** Object:  Table [dbo].[CityMaster_SP]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CityMaster_SP](
	[City_ID] [int] NULL,
	[City_Name] [varchar](100) NULL,
	[DistrictID] [int] NULL,
	[StateID] [int] NULL,
	[IsActive] [int] NULL,
	[IsDelete] [int] NULL
) ON [PRIMARY]
GO
