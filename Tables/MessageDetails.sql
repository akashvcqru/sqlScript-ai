/****** Object:  Table [dbo].[MessageDetails]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MessageDetails](
	[Message_id] [int] NOT NULL,
	[Compid] [varchar](20) NOT NULL,
	[MobileNo] [varchar](50) NOT NULL,
	[Isread] [int] NULL,
	[MessageReceived_On] [datetime] NULL,
	[MessageRead_On] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[Message_id] ASC,
	[Compid] ASC,
	[MobileNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
