/****** Object:  Table [dbo].[tbl_Util_UserRole]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_Util_UserRole](
	[USER_EMPID] [varchar](50) NULL,
	[USER_MAIL] [varchar](100) NULL,
	[Support] [bit] NULL,
	[Upload] [bit] NULL,
	[Update_ifsc] [bit] NULL,
	[Consumer_dtls] [bit] NULL,
	[Code_dtls] [bit] NULL,
	[Fake_product] [bit] NULL,
	[Paytm_report] [bit] NULL,
	[Code_report] [bit] NULL
) ON [PRIMARY]
GO
