/****** Object:  Table [dbo].[aliasproduct]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[aliasproduct](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[Product_name] [nvarchar](max) NULL,
	[Alias_name] [nvarchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
