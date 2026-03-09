/****** Object:  Table [dbo].[tbl_extrafield]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_extrafield](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[productname] [varchar](200) NULL,
	[others_field1] [varchar](200) NULL,
	[other_field2] [varchar](200) NULL,
	[comp_id] [varchar](50) NULL,
	[code1] [nvarchar](10) NULL,
	[code2] [nvarchar](16) NULL,
	[createddate] [datetime] NULL,
	[proenq_id] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
