/****** Object:  Table [dbo].[Channels]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Channels](
	[ChannelsID] [int] IDENTITY(1,1) NOT NULL,
	[Compid] [nvarchar](50) NULL,
	[name] [nvarchar](80) NULL,
	[createddate] [datetime] NULL,
	[createdby] [nvarchar](50) NULL,
	[updateddate] [datetime] NULL,
	[updatedby] [nvarchar](50) NULL,
 CONSTRAINT [PK_Channels] PRIMARY KEY CLUSTERED 
(
	[ChannelsID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
