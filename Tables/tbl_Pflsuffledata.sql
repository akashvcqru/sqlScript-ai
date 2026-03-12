/****** Object:  Table [dbo].[tbl_Pflsuffledata]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_Pflsuffledata](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Sno] [bigint] NOT NULL,
	[Searies_Name] [varchar](20) NOT NULL,
	[Code1] [varchar](10) NOT NULL,
	[Code2] [varchar](10) NOT NULL,
	[Completecode] [varchar](20) NOT NULL,
	[QRCode] [nvarchar](200) NOT NULL,
	[Imagefile] [nvarchar](200) NOT NULL,
	[BatchNo] [nvarchar](100) NOT NULL,
	[SKU] [nvarchar](100) NOT NULL,
	[Dateofmfg] [nvarchar](100) NOT NULL,
	[Dateofexpiry] [nvarchar](100) NOT NULL,
	[Usemark] [bit] NULL,
	[EntryDate] [datetime] NULL,
	[Remarks] [nvarchar](500) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
