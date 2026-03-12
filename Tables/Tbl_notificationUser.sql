/****** Object:  Table [dbo].[Tbl_notificationUser]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tbl_notificationUser](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[comp_id] [nvarchar](20) NOT NULL,
	[status] [bit] NULL,
	[created_at] [datetime] NOT NULL,
	[notificationmasterID] [int] NULL,
	[m_consumerid] [int] NULL,
	[apiurl] [varchar](200) NULL,
	[title] [varchar](150) NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
