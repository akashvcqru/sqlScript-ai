/****** Object:  Table [dbo].[M_LuckyNumber]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_LuckyNumber](
	[Row_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[SST_Id] [bigint] NULL,
	[LuckyNumber] [nvarchar](10) NULL,
	[Gift_ID] [bigint] NULL,
	[Code1] [numeric](5, 0) NULL,
	[Code2] [numeric](8, 0) NULL,
	[IsUsed] [int] NULL,
 CONSTRAINT [PK_M_LuckyNumber] PRIMARY KEY CLUSTERED 
(
	[Row_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
