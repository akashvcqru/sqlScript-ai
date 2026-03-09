/****** Object:  Table [dbo].[StateMaster_SP]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StateMaster_SP](
	[StateID] [int] NULL,
	[State_Name] [varchar](100) NULL,
	[CountryID] [int] NULL,
	[IsActive] [int] NULL,
	[IsDelete] [int] NULL
) ON [PRIMARY]
GO
