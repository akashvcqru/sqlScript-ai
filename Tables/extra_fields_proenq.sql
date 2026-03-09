/****** Object:  Table [dbo].[extra_fields_proenq]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[extra_fields_proenq](
	[code1] [int] NOT NULL,
	[code2] [int] NOT NULL,
	[name] [varchar](100) NULL,
	[designation] [varchar](100) NULL,
	[mobile] [varchar](50) NOT NULL,
	[is_success] [int] NOT NULL,
	[entry_date] [datetime] NOT NULL
) ON [PRIMARY]
GO
