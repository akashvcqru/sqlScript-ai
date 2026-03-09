/****** Object:  Table [dbo].[BPointsPaytm]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BPointsPaytm](
	[BPointsPaytmid] [int] IDENTITY(1,1) NOT NULL,
	[PaytmCode] [nvarchar](50) NULL,
	[TransactionID] [int] NULL,
	[Name] [nvarchar](50) NULL,
	[Points] [int] NULL,
 CONSTRAINT [PK_BPointsPaytm] PRIMARY KEY CLUSTERED 
(
	[BPointsPaytmid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
