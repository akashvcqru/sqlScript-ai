/****** Object:  Table [dbo].[claimredeem]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[claimredeem](
	[compid] [nvarchar](50) NOT NULL,
	[points] [int] NOT NULL,
	[p_cash] [int] NOT NULL
) ON [PRIMARY]
GO
