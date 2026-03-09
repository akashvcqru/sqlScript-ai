/****** Object:  Table [dbo].[tblUPITransactionDetails_temp]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblUPITransactionDetails_temp](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Comp_Id] [varchar](30) NULL,
	[M_Consumerid] [int] NULL,
	[Code1] [varchar](6) NULL,
	[Code2] [varchar](8) NULL,
	[Amount] [float] NULL,
	[Remarks] [varchar](70) NULL,
	[created_at] [datetime] NOT NULL
) ON [PRIMARY]
GO
