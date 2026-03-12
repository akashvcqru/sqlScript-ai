/****** Object:  Table [dbo].[pfl_20250704_lastadd]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[pfl_20250704_lastadd](
	[Sno] [bigint] IDENTITY(402058,1) NOT NULL,
	[Searies_Name] [nvarchar](255) NULL,
	[Code1] [nvarchar](255) NULL,
	[Code2] [nvarchar](255) NULL,
	[13-Digit Code] [nvarchar](255) NULL,
	[QRCode] [nvarchar](255) NULL,
	[ImageFile] [nvarchar](255) NULL,
	[isscraped] [bit] NULL,
	[Use_mark] [bit] NULL
) ON [PRIMARY]
GO
