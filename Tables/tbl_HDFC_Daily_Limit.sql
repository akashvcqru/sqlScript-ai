/****** Object:  Table [dbo].[tbl_HDFC_Daily_Limit]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_HDFC_Daily_Limit](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Comp_id] [varchar](20) NULL,
	[Limit] [int] NULL,
	[Entry_date] [datetime] NULL
) ON [PRIMARY]
GO
