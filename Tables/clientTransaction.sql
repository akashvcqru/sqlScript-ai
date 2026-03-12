/****** Object:  Table [dbo].[clientTransaction]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[clientTransaction](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[completeCode] [numeric](18, 0) NOT NULL,
	[mobileno] [nvarchar](50) NOT NULL,
	[username] [nvarchar](50) NULL,
	[city] [nvarchar](50) NULL,
	[email] [nvarchar](50) NULL,
	[comp_id] [nvarchar](50) NULL,
	[entrydate] [varchar](50) NULL
) ON [PRIMARY]
GO
