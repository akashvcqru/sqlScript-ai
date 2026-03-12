/****** Object:  Table [dbo].[JPCDeactivatedServices]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[JPCDeactivatedServices](
	[Pro_ID] [nvarchar](50) NOT NULL,
	[Pro_Name] [nvarchar](50) NULL,
	[Subscribe_Id] [nvarchar](50) NOT NULL,
	[Service_ID] [nvarchar](10) NOT NULL,
	[Plan_ID] [nvarchar](50) NULL,
	[PlanName] [nvarchar](150) NULL,
	[DateFrom] [datetime] NULL,
	[DateTo] [datetime] NULL,
	[start_order] [int] NULL,
	[start_series] [int] NULL,
	[end_order] [int] NULL,
	[end_series] [int] NULL
) ON [PRIMARY]
GO
