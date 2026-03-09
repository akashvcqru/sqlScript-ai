/****** Object:  Table [dbo].[ctetest]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ctetest](
	[user_id] [nvarchar](50) NOT NULL,
	[entry_date] [datetime] NULL,
	[mobileno] [nvarchar](50) NULL,
	[rn] [bigint] NULL
) ON [PRIMARY]
GO
