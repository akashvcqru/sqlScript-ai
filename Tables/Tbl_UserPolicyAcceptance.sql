/****** Object:  Table [dbo].[Tbl_UserPolicyAcceptance]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tbl_UserPolicyAcceptance](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Comp_Id] [nvarchar](15) NOT NULL,
	[PolicyVersion] [nvarchar](10) NULL,
	[AcceptedOn] [datetime] NULL,
	[AcceptedBy] [nvarchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
