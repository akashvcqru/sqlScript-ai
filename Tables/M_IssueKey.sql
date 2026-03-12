/****** Object:  Table [dbo].[M_IssueKey]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_IssueKey](
	[Row_ID] [int] IDENTITY(1,1) NOT NULL,
	[Comp_ID] [nvarchar](50) NULL,
	[Pro_ID] [nvarchar](50) NULL,
	[Sufix] [nvarchar](2) NULL,
	[SeriesQty] [numeric](18, 0) NULL,
	[Qty] [numeric](18, 0) NULL,
	[Batch_No] [nvarchar](50) NULL,
	[IsPrint] [int] NULL,
	[IsUsed] [int] NULL,
	[IsIssue] [int] NULL,
	[EntryDate] [datetime] NULL
) ON [PRIMARY]
GO
