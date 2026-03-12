/****** Object:  Table [dbo].[MenuItem]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MenuItem](
	[MenuItemID] [int] IDENTITY(1,1) NOT NULL,
	[MenuItemName] [nvarchar](100) NULL,
	[IsEnabled] [bit] NULL,
	[Request_Date] [datetime] NULL,
	[RefMenu] [int] NULL,
	[ControlName] [varchar](100) NULL,
	[URL] [varchar](500) NULL,
	[IconClass] [nvarchar](100) NULL
) ON [PRIMARY]
GO
