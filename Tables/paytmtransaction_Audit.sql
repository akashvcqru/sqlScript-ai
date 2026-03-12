/****** Object:  Table [dbo].[paytmtransaction_Audit]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[paytmtransaction_Audit](
	[ptranid] [int] IDENTITY(1,1) NOT NULL,
	[pdate] [datetime] NULL,
	[M_consumerid] [varchar](50) NULL,
	[mobileno] [varchar](14) NULL,
	[Amount] [int] NULL,
	[pstatus] [varchar](10) NULL,
	[compId] [varchar](18) NULL,
	[orderid] [varchar](30) NULL,
	[Rec_code1] [varchar](5) NULL,
	[Rec_code2] [varchar](8) NULL,
	[Comment] [varchar](max) NULL,
	[AccountNo] [varchar](30) NULL,
	[AccountHolderName] [varchar](70) NULL,
	[Mode] [varchar](5) NULL,
	[InqStatus] [varchar](20) NULL,
	[InqComment] [varchar](100) NULL,
	[IsIntra] [bit] NULL,
	[IFSCCode] [varchar](30) NULL,
	[Charge_Amount] [varchar](10) NULL,
	[Charge_Type] [bit] NULL,
	[TCharge_Amount] [varchar](10) NULL,
	[GstAmount] [varchar](10) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
