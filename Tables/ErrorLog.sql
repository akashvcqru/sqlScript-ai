/****** Object:  Table [dbo].[ErrorLog]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ErrorLog](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[ErrorLine] [int] NULL,
	[ErrorMessage] [nvarchar](2500) NULL,
	[ErrorNumber] [int] NULL,
	[ErrorProcedure] [nvarchar](128) NULL,
	[ErrorSeverity] [int] NULL,
	[ErrorState] [int] NULL,
	[DateErrorRaised] [datetime] NULL
) ON [PRIMARY]
GO
