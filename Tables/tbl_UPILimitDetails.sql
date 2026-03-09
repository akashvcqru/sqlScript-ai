/****** Object:  Table [dbo].[tbl_UPILimitDetails]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_UPILimitDetails](
	[Row_ID] [int] IDENTITY(1,1) NOT NULL,
	[Comp_ID] [nvarchar](50) NOT NULL,
	[Service_ID] [varchar](20) NOT NULL,
	[Daily_Limit] [float] NULL,
	[IsClaimReq] [bit] NULL,
	[IsApprovalReq] [bit] NULL
) ON [PRIMARY]
GO
