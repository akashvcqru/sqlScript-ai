/****** Object:  Table [dbo].[tblabc]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblabc](
	[m_consumerid] [int] NULL,
	[oldbal] [decimal](18, 2) NULL,
	[newbal] [decimal](18, 2) NULL,
	[amount] [decimal](18, 2) NULL,
	[reqdate] [datetime] NULL
) ON [PRIMARY]
GO
