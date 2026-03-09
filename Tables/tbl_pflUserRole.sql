/****** Object:  Table [dbo].[tbl_pflUserRole]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_pflUserRole](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[RoleType] [varchar](200) NULL,
	[Createddate] [datetime] NULL,
	[IsActive] [bit] NULL,
	[Isdelete] [bit] NULL,
	[Remark] [varchar](500) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
