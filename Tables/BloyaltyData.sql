/****** Object:  Table [dbo].[BloyaltyData]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BloyaltyData](
	[Pkid] [bigint] IDENTITY(1,1) NOT NULL,
	[SST_id] [bigint] NULL,
	[M_Consumer_MCOdeid] [bigint] NULL,
	[M_Cunsumerid] [bigint] NULL,
	[IsPointsAssigned] [bit] NULL,
	[Createdate] [datetime] NULL,
	[CreatedBy] [int] NULL,
	[rownumber] [bigint] NULL
) ON [PRIMARY]
GO
