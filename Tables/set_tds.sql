/****** Object:  Table [dbo].[set_tds]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[set_tds](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Comp_ID] [varchar](50) NOT NULL,
	[tds_status] [tinyint] NOT NULL,
	[tds_description] [varchar](100) NULL,
	[entry_date] [datetime] NOT NULL,
	[updated_date] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
