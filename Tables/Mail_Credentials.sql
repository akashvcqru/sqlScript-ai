/****** Object:  Table [dbo].[Mail_Credentials]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Mail_Credentials](
	[tbl_id] [int] IDENTITY(1,1) NOT NULL,
	[Email_Name] [nvarchar](50) NULL,
	[SMTP] [nvarchar](50) NULL,
	[User_ID] [nvarchar](50) NULL,
	[Password] [nvarchar](50) NULL,
 CONSTRAINT [PK__Mail_Credentials__5E1FF51F] PRIMARY KEY CLUSTERED 
(
	[tbl_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
