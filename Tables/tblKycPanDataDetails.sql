/****** Object:  Table [dbo].[tblKycPanDataDetails]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblKycPanDataDetails](
	[Id] [int] IDENTITY(1100000,1) NOT NULL,
	[M_Consumerid] [varchar](10) NULL,
	[InputPanName] [varchar](50) NULL,
	[PanName] [varchar](70) NULL,
	[PanRefrenceId] [varchar](100) NULL,
	[IspanVerify] [bit] NULL,
	[PanReqdate] [datetime] NULL,
	[PanRemarks] [varchar](255) NULL,
	[ResponseCode] [varchar](5) NULL,
	[NameMatchScore] [float] NULL,
	[PanReqCount] [char](1) NULL,
	[Status] [bit] NULL,
	[ReqCount] [char](1) NULL,
	[pancardNumber] [varchar](20) NULL,
	[KycMode] [nchar](10) NULL,
	[created_at] [datetime] NOT NULL,
	[dateofbirth] [varchar](50) NULL
) ON [PRIMARY]
GO
