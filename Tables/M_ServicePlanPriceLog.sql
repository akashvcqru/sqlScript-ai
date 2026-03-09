/****** Object:  Table [dbo].[M_ServicePlanPriceLog]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_ServicePlanPriceLog](
	[Trans_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Plan_ID] [nvarchar](50) NULL,
	[PlanPrice] [numeric](18, 0) NULL,
	[EntryDate] [datetime] NULL,
 CONSTRAINT [PK_M_ServicePriceTrans] PRIMARY KEY CLUSTERED 
(
	[Trans_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
