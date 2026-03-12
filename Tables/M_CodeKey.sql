/****** Object:  Table [dbo].[M_CodeKey]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_CodeKey](
	[Row_ID] [int] IDENTITY(1,1) NOT NULL,
	[Sufix] [nvarchar](2) NULL,
	[IsUsed] [int] NULL
) ON [PRIMARY]
GO
