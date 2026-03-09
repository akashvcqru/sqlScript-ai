/****** Object:  Table [dbo].[Getintouch]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Getintouch](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[fname] [varchar](35) NULL,
	[lname] [varchar](20) NULL,
	[email] [varchar](50) NULL,
	[phone] [varchar](25) NULL,
	[msg] [varchar](255) NULL,
	[createddate] [datetime] NULL,
	[updateddate] [datetime] NULL,
	[Reuested_page] [varchar](50) NULL
) ON [PRIMARY]
GO
