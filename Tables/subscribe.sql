/****** Object:  Table [dbo].[subscribe]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[subscribe](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[email] [varchar](60) NULL,
	[status] [bit] NULL,
	[createdby] [varchar](60) NULL,
	[createddate] [datetime] NULL,
	[updateddate] [datetime] NULL
) ON [PRIMARY]
GO
