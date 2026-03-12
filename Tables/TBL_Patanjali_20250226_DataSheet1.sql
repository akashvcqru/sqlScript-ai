/****** Object:  Table [dbo].[TBL_Patanjali_20250226_DataSheet1]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TBL_Patanjali_20250226_DataSheet1](
	[SNO] [int] IDENTITY(1,1) NOT NULL,
	[Searies_Name] [nvarchar](500) NULL,
	[Code1] [nvarchar](20) NULL,
	[Code2] [nvarchar](20) NULL,
	[FullCode] [nvarchar](500) NULL,
	[QRCode] [nvarchar](500) NULL,
	[ImageFile] [nvarchar](500) NULL,
PRIMARY KEY CLUSTERED 
(
	[SNO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
