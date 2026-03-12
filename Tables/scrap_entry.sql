/****** Object:  Table [dbo].[scrap_entry]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[scrap_entry](
	[Scrap_id] [int] IDENTITY(1,1) NOT NULL,
	[code1] [nvarchar](5) NULL,
	[code2] [nvarchar](8) NULL,
	[loyalty] [int] NULL,
	[comp_id] [nvarchar](50) NULL,
	[entry_date] [datetime] NULL
) ON [PRIMARY]
GO
