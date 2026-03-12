/****** Object:  Table [dbo].[tempjpc]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tempjpc](
	[Row_ID] [int] IDENTITY(1,1) NOT NULL,
	[PAN] [varchar](20) NULL,
	[DEALERSHIPNAME] [varchar](40) NULL,
	[MOBILENO] [varchar](10) NULL,
	[AdharNo] [varchar](20) NULL
) ON [PRIMARY]
GO
