/****** Object:  Table [dbo].[IVRCodeCheck]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[IVRCodeCheck](
	[tbl_id] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[Callsid] [nvarchar](50) NULL,
	[Digits] [nvarchar](50) NULL,
	[Language] [nvarchar](50) NULL,
	[Entry_Date] [datetime] NULL
) ON [PRIMARY]
GO
