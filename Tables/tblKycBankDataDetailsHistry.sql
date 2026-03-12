/****** Object:  Table [dbo].[tblKycBankDataDetailsHistry]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblKycBankDataDetailsHistry](
	[Id] [int] IDENTITY(2000000,1) NOT NULL,
	[M_Consumerid] [varchar](10) NULL,
	[AccountHolderName] [varchar](70) NULL,
	[BankRefrenceId] [varchar](100) NULL,
	[IsBankAccountVerify] [bit] NULL,
	[BankReqdate] [datetime] NULL,
	[BankReqCount] [char](1) NULL,
	[BankRemarks] [varchar](255) NULL,
	[ResponseCode] [varchar](5) NULL,
	[Status] [bit] NULL,
	[ReqCount] [char](1) NULL,
	[IFSC_Code] [varchar](20) NULL,
	[AccountNo] [varchar](20) NULL,
	[KycMode] [nchar](20) NULL,
	[created_at] [datetime] NULL
) ON [PRIMARY]
GO
