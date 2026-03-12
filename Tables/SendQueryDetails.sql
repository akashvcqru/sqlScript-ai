/****** Object:  Table [dbo].[SendQueryDetails]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SendQueryDetails](
	[Row_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](150) NULL,
	[Mobile_No] [nvarchar](150) NULL,
	[Email] [nvarchar](150) NULL,
	[Query_Txt] [nvarchar](1050) NULL
) ON [PRIMARY]
GO
