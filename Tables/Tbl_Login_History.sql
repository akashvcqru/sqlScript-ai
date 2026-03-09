/****** Object:  Table [dbo].[Tbl_Login_History]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tbl_Login_History](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Email] [varchar](200) NULL,
	[Comp_ID] [varchar](20) NULL,
	[LoginTime] [datetime] NULL,
	[IPAddress] [varchar](100) NULL,
	[BrowserInfo] [varchar](500) NULL,
	[DeviceInfo] [varchar](500) NULL,
	[OperatingSystem] [varchar](200) NULL,
	[IsSuccess] [bit] NULL,
	[Message] [varchar](200) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
