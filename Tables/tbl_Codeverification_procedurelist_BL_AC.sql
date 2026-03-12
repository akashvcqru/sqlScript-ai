/****** Object:  Table [dbo].[tbl_Codeverification_procedurelist_BL_AC]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_Codeverification_procedurelist_BL_AC](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Comp_id] [varchar](20) NULL,
	[Procedure_name] [varchar](100) NULL,
	[Selected_column] [varchar](max) NULL,
	[Isactive] [bit] NULL,
	[Isdelete] [bit] NULL,
	[Remark] [varchar](100) NULL,
	[Created_date] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
