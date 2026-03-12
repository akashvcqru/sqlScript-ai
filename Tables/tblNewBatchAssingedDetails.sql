/****** Object:  Table [dbo].[tblNewBatchAssingedDetails]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblNewBatchAssingedDetails](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[M_CodeId] [int] NULL,
	[Old_Pro_ID] [varchar](8) NULL,
	[Old_SerialCode] [varchar](30) NULL,
	[Old_Batch_No] [varchar](30) NULL,
	[New_Pro_ID] [varchar](8) NULL,
	[New_SerialCode] [varchar](30) NULL,
	[New_Batch_No] [varchar](30) NULL,
	[ReqDate] [datetime] NULL,
	[Manufactured_date] [datetime] NULL,
	[Expiry_date] [datetime] NULL,
	[Isscraped] [bit] NULL,
	[Scrapeddate] [datetime] NULL,
	[Scrapedby] [varchar](100) NULL,
	[Assignedby] [nvarchar](200) NULL,
	[Updated_date] [datetime] NULL
) ON [PRIMARY]
GO
