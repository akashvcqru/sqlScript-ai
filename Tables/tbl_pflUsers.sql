/****** Object:  Table [dbo].[tbl_pflUsers]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_pflUsers](
	[UserRole_id] [int] IDENTITY(1001,1) NOT NULL,
	[UserRoleType] [int] NULL,
	[UserName] [varchar](200) NULL,
	[UserEmail] [varchar](200) NULL,
	[UserMobile] [varchar](13) NULL,
	[UserPassword] [varchar](100) NULL,
	[MappedCompId] [varchar](200) NULL,
	[Created_Date] [datetime] NULL,
	[IsActive] [bit] NULL,
	[IsDelete] [bit] NULL,
	[Remark] [varchar](500) NULL,
	[Is_Emailverify] [bit] NULL,
 CONSTRAINT [PK_tbl_pflUsers] PRIMARY KEY CLUSTERED 
(
	[UserRole_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
