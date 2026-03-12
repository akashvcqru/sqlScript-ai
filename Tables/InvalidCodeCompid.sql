/****** Object:  Table [dbo].[InvalidCodeCompid]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[InvalidCodeCompid](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ApiComp_ID] [varchar](100) NULL,
	[DbComp_ID] [varchar](100) NULL,
	[Code1] [varchar](100) NULL,
	[Code2] [varchar](100) NULL,
	[Pro_ID] [varchar](100) NULL,
	[MobileNo] [varchar](20) NULL,
	[Enq_Date] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
