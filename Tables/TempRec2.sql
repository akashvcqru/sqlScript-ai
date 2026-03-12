/****** Object:  Table [dbo].[TempRec2]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TempRec2](
	[M_Consumer_MCodeid] [numeric](18, 0) NOT NULL,
	[M_Consumerid] [numeric](18, 0) NULL,
	[M_Codeid] [numeric](18, 0) NULL,
	[Pro_id] [nvarchar](50) NULL,
	[CreatedDate] [datetime] NULL,
	[Compid] [nvarchar](50) NULL
) ON [PRIMARY]
GO
