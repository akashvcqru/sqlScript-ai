/****** Object:  Table [dbo].[Partner_Reg]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Partner_Reg](
	[PartnerID] [nvarchar](50) NOT NULL,
	[Name] [nvarchar](50) NULL,
	[Mobile_No] [nvarchar](50) NULL,
	[Address] [nvarchar](max) NULL,
	[Email] [nvarchar](50) NULL,
	[PANNo] [nvarchar](50) NULL,
	[PanDoc] [nvarchar](50) NULL,
	[IDProof] [nvarchar](50) NULL,
	[AddProof] [nvarchar](50) NULL,
	[AccountNo] [nvarchar](50) NULL,
	[Photo] [nvarchar](50) NULL,
	[Flag] [numeric](18, 0) NULL,
	[Entry_Date] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
