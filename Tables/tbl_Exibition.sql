/****** Object:  Table [dbo].[tbl_Exibition]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_Exibition](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[Mobile] [varchar](13) NULL,
	[Name] [varchar](200) NULL,
	[Email] [varchar](100) NULL,
	[Companyname] [varchar](500) NULL,
	[Designation] [varchar](100) NULL,
	[Intrest] [varchar](20) NULL,
	[Exibitionname] [varchar](200) NULL,
	[Date] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
