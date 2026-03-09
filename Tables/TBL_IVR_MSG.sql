/****** Object:  Table [dbo].[TBL_IVR_MSG]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TBL_IVR_MSG](
	[MSG_ID] [int] IDENTITY(1,1) NOT NULL,
	[LANG_ID] [int] NULL,
	[SVC_ID] [varchar](50) NULL,
	[STATUS_ID] [int] NULL,
	[MESSAGE] [nvarchar](max) NULL,
	[SOUND_FILE_PATH] [varchar](max) NULL,
	[NOTES] [varchar](max) NULL,
	[CREATED_DATE] [datetime] NULL,
	[CREATED_BY] [bigint] NULL,
	[UPDATED_DATE] [datetime] NULL,
	[UPDATED_BY] [bigint] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
