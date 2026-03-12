/****** Object:  Table [dbo].[MarmoCashPayout]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MarmoCashPayout](
	[User Number] [nvarchar](255) NULL,
	[BANK NAME] [nvarchar](255) NULL,
	[User Name] [nvarchar](255) NULL,
	[BANK ACCOUNT NUMBER] [nvarchar](255) NULL,
	[IFSC CODE] [nvarchar](255) NULL,
	[Amount Won] [float] NULL,
	[Transaction ID] [nvarchar](255) NULL,
	[Transaction Status] [nvarchar](255) NULL,
	[Transaction Date] [datetime] NULL,
	[F10] [nvarchar](255) NULL,
	[F11] [nvarchar](255) NULL
) ON [PRIMARY]
GO
