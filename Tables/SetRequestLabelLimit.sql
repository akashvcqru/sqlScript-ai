/****** Object:  Table [dbo].[SetRequestLabelLimit]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SetRequestLabelLimit](
	[Row_ID] [int] IDENTITY(1,1) NOT NULL,
	[Comp_ID] [varchar](10) NULL,
	[Pro_ID] [varchar](50) NULL,
	[MonthlyLimit] [bigint] NULL,
	[Req_Date] [datetime] NULL,
	[IsApproved] [tinyint] NULL,
	[Approved_Date] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[Row_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
