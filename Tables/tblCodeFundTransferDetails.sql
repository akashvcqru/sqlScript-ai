/****** Object:  Table [dbo].[tblCodeFundTransferDetails]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblCodeFundTransferDetails](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[CompleteCode] [varchar](13) NULL,
	[BeneficiaryCode] [varchar](17) NULL,
	[BeneBankName] [varchar](30) NULL,
	[BeneAccountNumber] [varchar](20) NULL,
	[BeneIfsccode] [varchar](16) NULL,
	[BeneName] [varchar](70) NULL,
	[BeneBranchName] [varchar](60) NULL,
	[BeneEmailId] [varchar](30) NULL,
	[InstrumentAmount] [decimal](18, 2) NULL,
	[CustomerReferenceNumber] [varchar](20) NULL,
	[Latitude] [varchar](15) NULL,
	[Longitude] [varchar](15) NULL,
	[Ipaddress] [varchar](20) NULL,
	[MacAddress] [varchar](25) NULL,
	[TrnDate] [datetime] NULL,
	[ReqDate] [datetime] NULL,
	[TransactionType] [varchar](20) NULL,
	[IsDelete] [bit] NULL,
	[ReportNumber] [varchar](30) NULL,
	[CompId] [varchar](25) NULL,
	[IsPayoutReleased] [bit] NULL,
	[M_Consumerid] [int] NULL,
	[NeedApproval] [varchar](1) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
