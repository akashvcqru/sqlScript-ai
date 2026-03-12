/****** Object:  Table [dbo].[EmpMeeting_CardUpload]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EmpMeeting_CardUpload](
	[EmpMeeting_CardUploadid] [int] IDENTITY(1,1) NOT NULL,
	[Meetingid] [int] NULL,
	[FileUploadName] [nvarchar](250) NULL,
	[FileUploadOriginalName] [nvarchar](250) NULL,
 CONSTRAINT [PK_EmpMeeting_CardUpload] PRIMARY KEY CLUSTERED 
(
	[EmpMeeting_CardUploadid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
