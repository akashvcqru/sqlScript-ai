/****** Object:  Table [dbo].[tblNotification]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblNotification](
	[Row_ID] [int] IDENTITY(1,1) NOT NULL,
	[Comp_ID] [varchar](20) NULL,
	[Code1] [varchar](5) NULL,
	[code2] [varchar](8) NULL,
	[Total] [int] NULL,
	[CreationDate] [datetime] NULL,
	[IsRead] [bit] NULL
) ON [PRIMARY]
GO
