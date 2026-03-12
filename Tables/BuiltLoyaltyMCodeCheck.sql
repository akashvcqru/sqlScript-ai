/****** Object:  Table [dbo].[BuiltLoyaltyMCodeCheck]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BuiltLoyaltyMCodeCheck](
	[Pkid] [bigint] IDENTITY(1,1) NOT NULL,
	[SST_id] [bigint] NULL,
	[M_Consumer_MCOdeid] [bigint] NULL,
	[M_Cunsumerid] [bigint] NULL,
	[IsPointsAssigned] [bit] NULL,
	[Createdate] [datetime] NULL,
	[CreatedBy] [int] NULL,
 CONSTRAINT [PK_BuiltLoyaltyMCodeCheck] PRIMARY KEY CLUSTERED 
(
	[Pkid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
