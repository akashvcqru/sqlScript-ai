/****** Object:  Table [dbo].[Transaction_status]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Transaction_status](
	[Complete_code] [numeric](18, 0) NULL,
	[Transaction_Status] [nvarchar](50) NULL,
	[Transaction_date] [datetime] NULL
) ON [PRIMARY]
GO
