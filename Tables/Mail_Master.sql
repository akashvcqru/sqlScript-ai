/****** Object:  Table [dbo].[Mail_Master]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Mail_Master](
	[Mail_id] [nvarchar](50) NOT NULL,
	[Entry_Date] [datetime] NULL,
	[Mail_From] [nvarchar](100) NULL,
	[Mail_CC] [nvarchar](500) NULL,
	[Mail_Subject] [nvarchar](300) NULL,
	[Mail_Message] [nvarchar](max) NULL,
	[Mail_Attachment] [nvarchar](100) NULL,
	[Del_Flg] [tinyint] NULL,
 CONSTRAINT [PK_Mail_Master] PRIMARY KEY CLUSTERED 
(
	[Mail_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
