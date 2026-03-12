/****** Object:  Table [dbo].[BigDataAnalysisData]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BigDataAnalysisData](
	[BigDataAnalysisDataid] [bigint] IDENTITY(1,1) NOT NULL,
	[DataQty] [int] NULL,
	[Price] [int] NULL,
	[CreatedDate] [datetime] NULL,
	[Createdby] [int] NULL,
	[ModifiedDate] [datetime] NULL,
	[ModifiedBy] [int] NULL,
	[IsActive1] [int] NULL,
	[Isdelete1] [int] NULL,
 CONSTRAINT [PK_BigDataAnalysisData] PRIMARY KEY CLUSTERED 
(
	[BigDataAnalysisDataid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
