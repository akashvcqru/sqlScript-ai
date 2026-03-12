/****** Object:  Table [dbo].[tbl_RankedPoints_DateRangeType]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_RankedPoints_DateRangeType](
	[S.No] [bigint] NULL,
	[Mobile Number] [nvarchar](10) NULL,
	[Name] [nvarchar](150) NULL,
	[Points Found] [decimal](38, 2) NULL,
	[Amount Earned] [decimal](38, 2) NULL,
	[DateRangeType] [varchar](7) NOT NULL
) ON [PRIMARY]
GO
