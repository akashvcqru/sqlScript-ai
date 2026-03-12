/****** Object:  Table [dbo].[Use_CountNull]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Use_CountNull](
	[code1] [numeric](5, 0) NOT NULL,
	[code2] [numeric](8, 0) NOT NULL,
	[use_count] [numeric](5, 0) NULL
) ON [PRIMARY]
GO
