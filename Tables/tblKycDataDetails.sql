/****** Object:  Table [dbo].[tblKycDataDetails]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblKycDataDetails](
	[Id] [int] IDENTITY(1900000,1) NOT NULL,
	[M_Consumerid] [varchar](10) NULL,
	[AadharName] [varchar](70) NULL,
	[AadharRefrenceId] [varchar](100) NULL,
	[IsaadharVerify] [bit] NULL,
	[AadharReqdate] [datetime] NULL,
	[AadahaReqCount] [char](1) NULL,
	[PanName] [varchar](70) NULL,
	[PanRefrenceId] [varchar](100) NULL,
	[IspanVerify] [bit] NULL,
	[PanReqdate] [datetime] NULL,
	[PanReqCount] [char](1) NULL,
	[AccountHolderName] [varchar](70) NULL,
	[BankRefrenceId] [varchar](100) NULL,
	[IsBankAccountVerify] [bit] NULL,
	[BankReqdate] [datetime] NULL,
	[BankReqCount] [char](1) NULL,
	[Status] [bit] NULL,
	[ReqCount] [char](1) NULL,
	[pancardNumber] [varchar](50) NULL,
	[adhar_number] [varchar](50) NULL,
	[AccountNo] [varchar](50) NULL,
	[IFSC_Code] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
