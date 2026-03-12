/****** Object:  Table [dbo].[M_ServicePlan]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_ServicePlan](
	[Plan_ID] [nvarchar](50) NOT NULL,
	[Service_ID] [nvarchar](10) NOT NULL,
	[PlanName] [nvarchar](150) NULL,
	[PlanPeriod] [numeric](10, 0) NULL,
	[PlanPrice] [numeric](18, 0) NULL,
	[EntryDate] [datetime] NULL,
	[IsActive] [int] NULL,
	[IsDelete] [int] NULL,
 CONSTRAINT [PK_M_ServicePrice] PRIMARY KEY CLUSTERED 
(
	[Plan_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
