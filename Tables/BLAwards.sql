/****** Object:  Table [dbo].[BLAwards]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BLAwards](
	[BLAwards] [int] IDENTITY(1,1) NOT NULL,
	[vM_Consumerid] [int] NULL,
	[Points] [int] NULL,
	[cash] [int] NULL,
	[gift] [int] NULL,
	[sst_id] [int] NULL,
	[Earned] [bit] NULL,
	[CReateddate] [datetime] NULL,
	[ServiceName] [nvarchar](50) NULL,
	[Comp_id] [nvarchar](50) NULL,
	[UpdatedDate] [datetime] NULL,
	[PendingPoints] [int] NULL,
 CONSTRAINT [PK_BLAwards] PRIMARY KEY CLUSTERED 
(
	[BLAwards] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
