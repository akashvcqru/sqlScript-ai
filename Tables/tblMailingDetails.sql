/****** Object:  Table [dbo].[tblMailingDetails]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblMailingDetails](
	[mdid] [int] IDENTITY(1,1) NOT NULL,
	[tomail] [varchar](120) NULL,
	[ccmail] [varchar](100) NULL,
	[mtype] [varchar](12) NULL,
	[purpose] [varchar](25) NULL
) ON [PRIMARY]
GO
