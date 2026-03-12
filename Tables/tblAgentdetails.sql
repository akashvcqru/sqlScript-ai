/****** Object:  Table [dbo].[tblAgentdetails]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblAgentdetails](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[AgentName] [varchar](50) NULL,
	[LoginId] [varchar](30) NULL,
	[Password] [varchar](20) NULL,
	[RoleType] [varchar](15) NULL,
	[MobileNo] [varchar](12) NULL,
	[EmailId] [varchar](30) NULL,
	[IsActive] [bit] NULL,
	[ReqDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
