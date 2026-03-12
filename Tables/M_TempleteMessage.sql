/****** Object:  Table [dbo].[M_TempleteMessage]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_TempleteMessage](
	[Message_Id] [nvarchar](50) NOT NULL,
	[MsgBody] [nvarchar](250) NULL,
	[Service_ID] [nvarchar](15) NULL,
	[SubHeadId] [nvarchar](50) NULL,
	[MsgFor] [nvarchar](50) NULL,
	[MsgType] [int] NULL,
	[IsActive] [int] NULL,
	[IsDelete] [int] NULL,
	[IsCustomise] [int] NULL,
 CONSTRAINT [PK_M_TempleteMessage] PRIMARY KEY CLUSTERED 
(
	[Message_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
