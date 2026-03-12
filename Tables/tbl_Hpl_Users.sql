/****** Object:  Table [dbo].[tbl_Hpl_Users]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_Hpl_Users](
	[Userrole_id] [int] IDENTITY(1,1) NOT NULL,
	[Username] [varchar](100) NULL,
	[UserEmail] [varchar](100) NULL,
	[UserPassword] [varchar](100) NULL,
	[MobileNo] [varchar](12) NULL,
	[Location] [varchar](500) NULL,
	[MappedCompid] [varchar](20) NULL,
	[AssignProduct] [varchar](100) NULL,
	[CreatedDate] [datetime] NULL,
	[IsActive] [bit] NULL,
	[Isdelete] [bit] NULL,
	[Remark] [varchar](500) NULL,
PRIMARY KEY CLUSTERED 
(
	[Userrole_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
