/****** Object:  Table [dbo].[tblPaytmPaymentDetails]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblPaytmPaymentDetails](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[M_Consumerid] [int] NULL,
	[Amount] [float] NULL,
	[OpeningBal] [float] NULL,
	[ClosingBal] [float] NULL,
	[TreferenceId] [varchar](20) NULL,
	[Mode] [varchar](7) NULL,
	[Status] [varchar](15) NULL,
	[EditDate] [datetime] NULL,
	[ReqDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
