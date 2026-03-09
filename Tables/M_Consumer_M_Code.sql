/****** Object:  Table [dbo].[M_Consumer_M_Code]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_Consumer_M_Code](
	[M_Consumer_MCodeid] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[M_Consumerid] [numeric](18, 0) NULL,
	[M_Codeid] [numeric](18, 0) NULL,
	[Pro_id] [nvarchar](50) NULL,
	[CreatedDate] [datetime] NULL,
	[Compid] [nvarchar](50) NULL,
 CONSTRAINT [PK_M_Consumer_M_Code] PRIMARY KEY CLUSTERED 
(
	[M_Consumer_MCodeid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
