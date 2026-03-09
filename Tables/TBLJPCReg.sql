/****** Object:  Table [dbo].[TBLJPCReg]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TBLJPCReg](
	[Row_ID] [int] IDENTITY(1,1) NOT NULL,
	[PAN] [nvarchar](40) NULL,
	[DEALERSHIPNAME] [nvarchar](200) NULL,
	[MOBILENO] [nvarchar](10) NULL,
	[AdharNo] [nvarchar](20) NULL,
	[City] [varchar](100) NULL
) ON [PRIMARY]
GO
