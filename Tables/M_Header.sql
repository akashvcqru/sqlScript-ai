/****** Object:  Table [dbo].[M_Header]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_Header](
	[ID] [int] NULL,
	[Name] [nvarchar](500) NULL,
	[Address] [nvarchar](500) NULL,
	[VAT] [nvarchar](50) NULL,
	[PAN] [nvarchar](50) NULL,
	[VAT_RegNo] [nvarchar](50) NULL
) ON [PRIMARY]
GO
