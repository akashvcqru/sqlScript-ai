/****** Object:  Table [dbo].[T_RunSurveys]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_RunSurveys](
	[RowId] [bigint] IDENTITY(1,1) NOT NULL,
	[Pro_ID] [nvarchar](15) NULL,
	[Rating] [int] NULL,
	[MobileNo] [numeric](12, 0) NULL,
	[EntryDate] [datetime] NULL
) ON [PRIMARY]
GO
