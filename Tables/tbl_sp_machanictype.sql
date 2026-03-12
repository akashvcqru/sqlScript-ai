/****** Object:  Table [dbo].[tbl_sp_machanictype]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_sp_machanictype](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Mechanic_Type] [varchar](100) NULL,
	[Created_date] [datetime] NULL,
	[Isactive] [bit] NULL,
	[Isdelete] [bit] NULL,
	[Remark] [varchar](100) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
