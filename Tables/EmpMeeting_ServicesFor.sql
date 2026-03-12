/****** Object:  Table [dbo].[EmpMeeting_ServicesFor]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EmpMeeting_ServicesFor](
	[EmpMeeting_ServicesForId] [int] IDENTITY(1,1) NOT NULL,
	[Meetingid] [int] NOT NULL,
	[Services] [nvarchar](50) NULL,
 CONSTRAINT [PK_EmpMeeting_ServicesFor] PRIMARY KEY CLUSTERED 
(
	[EmpMeeting_ServicesForId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
