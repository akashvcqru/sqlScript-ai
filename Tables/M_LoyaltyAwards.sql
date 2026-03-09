/****** Object:  Table [dbo].[M_LoyaltyAwards]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_LoyaltyAwards](
	[RowId] [bigint] IDENTITY(1,1) NOT NULL,
	[Comp_ID] [nvarchar](50) NULL,
	[Points] [numeric](18, 0) NULL,
	[AwardName] [nvarchar](500) NULL,
	[IsActive] [int] NULL,
	[IsDelete] [int] NULL,
	[Entry_Date] [datetime] NULL,
 CONSTRAINT [PK_M_LoyaltyAwards] PRIMARY KEY CLUSTERED 
(
	[RowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
