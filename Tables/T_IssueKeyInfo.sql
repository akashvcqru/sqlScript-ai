/****** Object:  Table [dbo].[T_IssueKeyInfo]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_IssueKeyInfo](
	[Trans_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Row_ID] [bigint] NOT NULL,
	[Pro_ID] [nvarchar](50) NULL,
	[Series_From] [nvarchar](50) NULL,
	[Series_To] [nvarchar](50) NULL,
	[Qty] [int] NULL,
	[Entry_Date] [datetime] NULL,
 CONSTRAINT [PK__T_IssueKeyInfo_6442E2C9] PRIMARY KEY CLUSTERED 
(
	[Trans_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
