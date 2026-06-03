/****** Object:  Table [dbo].[tblWhatsAppWalletBalance]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblWhatsAppWalletBalance](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Comp_Id] [varchar](50) NULL,
	[OldBal] [decimal](18, 2) NULL,
	[NewBal] [decimal](18, 2) NULL,
	[Amount] [decimal](18, 2) NULL,
	[Cr_Dr_Type] [varchar](10) NULL,
	[ReqDate] [datetime] NULL,
	[Updated_date] [datetime] NULL,
	[Remarks] [varchar](255) NULL,
	[PaymentGatewayTxnId] [varchar](100) NULL,
	[Status] [varchar](20) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
