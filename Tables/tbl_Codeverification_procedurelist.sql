/****** Object:  Table [dbo].[tbl_Codeverification_procedurelist]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_Codeverification_procedurelist](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Comp_id] [varchar](10) NULL,
	[Proc_Name] [varchar](200) NULL,
	[Selected_Column] [varchar](max) NULL,
	[Isactive] [bit] NULL,
	[isdelete] [bit] NULL,
	[Remark] [varchar](500) NULL,
	[Created_date] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
