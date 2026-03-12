/****** Object:  Table [dbo].[CodeLocation]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CodeLocation](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[code1] [numeric](5, 0) NULL,
	[code2] [numeric](8, 0) NULL,
	[mobilno] [nvarchar](13) NULL,
	[latitude] [nvarchar](50) NULL,
	[longitude] [nvarchar](50) NULL,
	[city] [nvarchar](50) NULL,
	[state] [nvarchar](50) NULL,
	[country] [nvarchar](50) NULL,
	[address] [nvarchar](max) NULL,
	[entrydate] [datetime] NULL,
	[PostalCode] [nvarchar](20) NULL,
 CONSTRAINT [PK_CodeLocation] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
