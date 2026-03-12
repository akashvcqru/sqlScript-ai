/****** Object:  Table [dbo].[PFL_Login_History]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PFL_Login_History](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[LoginID] [varchar](200) NULL,
	[LoginDate] [datetime] NULL,
	[Logout_Date] [datetime] NULL,
	[UserName] [varchar](200) NULL,
	[Remark] [varchar](500) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
