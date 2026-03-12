/****** Object:  Table [dbo].[tbl_blockUpidd]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_blockUpidd](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[M_consumerId] [int] NULL,
	[Comp_id] [varchar](20) NULL,
	[Entry_date] [datetime] NULL,
	[IsActive] [int] NOT NULL,
	[numOfDayes] [varchar](20) NULL,
	[UPIId] [varchar](50) NULL
) ON [PRIMARY]
GO
