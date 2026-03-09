/****** Object:  Table [dbo].[vr_copper_detail]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[vr_copper_detail](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[title] [nvarchar](150) NOT NULL,
	[price] [nvarchar](200) NOT NULL,
	[detail] [nvarchar](500) NULL,
	[sortDesc] [nvarchar](100) NULL,
	[validTillTime] [nvarchar](100) NULL,
	[validTillDate] [nvarchar](30) NULL,
	[imagePath] [text] NULL,
	[status] [bit] NOT NULL,
	[created_at] [datetime] NOT NULL,
	[updated_at] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[title] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
