/****** Object:  Table [dbo].[tblKycAadharDataDetailsHistry]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblKycAadharDataDetailsHistry](
	[Id] [int] IDENTITY(1500000,1) NOT NULL,
	[M_Consumerid] [varchar](10) NULL,
	[AadharNo] [varchar](17) NULL,
	[AadharName] [varchar](70) NULL,
	[AadharRefrenceId] [varchar](100) NULL,
	[IsaadharVerify] [bit] NULL,
	[AadharReqdate] [datetime] NULL,
	[AadharRemarks] [varchar](255) NULL,
	[ResponseCode] [varchar](5) NULL,
	[AadahaReqCount] [char](1) NULL,
	[Status] [bit] NULL,
	[ReqCount] [char](1) NULL,
	[KycMode] [nchar](20) NULL,
	[created_at] [datetime] NOT NULL
) ON [PRIMARY]
GO
