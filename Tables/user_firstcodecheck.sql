/****** Object:  Table [dbo].[user_firstcodecheck]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[user_firstcodecheck](
	[row_id] [int] IDENTITY(1,1) NOT NULL,
	[m_consumerid] [int] NOT NULL,
	[date_span] [datetime] NOT NULL,
	[createddate] [datetime] NOT NULL,
 CONSTRAINT [PK_user_firstcodecheck] PRIMARY KEY CLUSTERED 
(
	[row_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
