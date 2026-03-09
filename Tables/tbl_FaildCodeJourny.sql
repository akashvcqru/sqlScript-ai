/****** Object:  Table [dbo].[tbl_FaildCodeJourny]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_FaildCodeJourny](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Code1] [int] NULL,
	[Code2] [int] NULL,
	[SST_Id] [int] NULL,
	[M_consumer_M_Code] [bigint] NULL,
	[Comp_id] [varchar](20) NULL,
	[Is_Used] [bit] NULL,
	[Entery_Date] [datetime] NULL,
	[Updated_Date] [datetime] NULL,
	[Remarks] [varchar](500) NULL,
	[Preprocess] [nvarchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
