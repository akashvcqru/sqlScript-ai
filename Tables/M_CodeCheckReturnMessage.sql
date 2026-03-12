/****** Object:  Table [dbo].[M_CodeCheckReturnMessage]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_CodeCheckReturnMessage](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[MsgBody] [nvarchar](max) NULL,
	[Service_ID] [nvarchar](15) NULL,
	[SubHeadId] [nvarchar](50) NULL,
	[MsgFor] [nvarchar](50) NULL,
	[MsgType] [int] NULL,
	[IsActive] [int] NULL,
	[IsDelete] [int] NULL,
	[IsCustomise] [int] NULL,
	[templateId] [varchar](50) NULL,
	[entityId] [varchar](50) NULL,
	[comp_id] [varchar](30) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
