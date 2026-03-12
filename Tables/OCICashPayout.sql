/****** Object:  Table [dbo].[OCICashPayout]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OCICashPayout](
	[User Number] [nvarchar](255) NULL,
	[Account Holder Name] [nvarchar](255) NULL,
	[Bank Name] [nvarchar](255) NULL,
	[Account Number] [nvarchar](255) NULL,
	[IFSC CODE] [nvarchar](255) NULL,
	[BRANCH] [nvarchar](255) NULL,
	[Count of Completecode] [float] NULL,
	[Sum of Amount_Won] [float] NULL,
	[Transaction Date] [datetime] NULL,
	[Transaction ID] [nvarchar](255) NULL,
	[Status] [nvarchar](255) NULL
) ON [PRIMARY]
GO
