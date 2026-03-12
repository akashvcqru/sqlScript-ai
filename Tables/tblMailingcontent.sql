/****** Object:  Table [dbo].[tblMailingcontent]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblMailingcontent](
	[mid] [int] IDENTITY(1,1) NOT NULL,
	[subject] [varchar](100) NULL,
	[body] [varchar](200) NULL,
	[mtype] [varchar](12) NULL,
	[purpose] [varchar](25) NULL
) ON [PRIMARY]
GO
