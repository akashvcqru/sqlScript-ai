/****** Object:  Table [dbo].[WebsiteHitHistory]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WebsiteHitHistory](
	[HitID] [numeric](20, 0) IDENTITY(1,1) NOT NULL,
	[Dial_Mode] [nvarchar](30) NULL,
	[LoginDate] [datetime] NULL,
	[Login_browser] [nvarchar](50) NULL,
 CONSTRAINT [PK_WebsiteHitHistory123] PRIMARY KEY CLUSTERED 
(
	[HitID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
