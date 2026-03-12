/****** Object:  Table [dbo].[tbl_leaderboard_BI]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_leaderboard_BI](
	[S_no] [int] NULL,
	[Mobile_Number] [varchar](20) NULL,
	[Name] [varchar](20) NULL,
	[Points_Found] [decimal](18, 2) NULL,
	[Amount_Earned] [decimal](18, 2) NULL,
	[DateRangeType] [varchar](10) NULL,
	[companyid] [varchar](20) NULL
) ON [PRIMARY]
GO
