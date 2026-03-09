/****** Object:  Table [dbo].[BBigDataAnalysis]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BBigDataAnalysis](
	[BigDataId] [bigint] IDENTITY(1,1) NOT NULL,
	[comp_idFrom] [nvarchar](50) NULL,
	[comp_idTo] [nvarchar](50) NULL,
	[DataQty] [int] NULL,
	[Price] [int] NULL,
	[CreatedDate] [datetime] NULL,
	[CreatedBY] [nvarchar](50) NULL,
	[IsActive] [bit] NULL,
	[IsDelete] [bit] NULL,
	[UpdatedDate] [datetime] NULL,
	[UpddatedBy] [nvarchar](50) NULL,
	[DataStatus] [int] NULL,
	[Comp_id] [nvarchar](50) NULL,
	[flag] [int] NULL,
 CONSTRAINT [PK_BBigDataAnalysis] PRIMARY KEY CLUSTERED 
(
	[BigDataId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
