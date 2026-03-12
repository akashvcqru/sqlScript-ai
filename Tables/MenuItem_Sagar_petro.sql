/****** Object:  Table [dbo].[MenuItem_Sagar_petro]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MenuItem_Sagar_petro](
	[MenuItemID] [int] IDENTITY(1,1) NOT NULL,
	[MenuItemName] [nvarchar](100) NULL,
	[IsEnabled] [bit] NULL,
	[Request_Date] [datetime] NULL,
	[RefMenu] [int] NULL
) ON [PRIMARY]
GO
