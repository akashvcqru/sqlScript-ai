/****** Object:  Table [dbo].[M_Code_C_PFL]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_Code_C_PFL](
	[id] [numeric](20, 0) NULL,
	[code1] [numeric](5, 0) NULL,
	[code2] [numeric](8, 0) NULL,
	[QRCode] [varbinary](max) NULL,
	[createdate] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
