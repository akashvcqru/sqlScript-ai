/****** Object:  Table [dbo].[BrandData_MHCroneJob]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BrandData_MHCroneJob](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Comp_ID] [nvarchar](50) NOT NULL,
	[Total_User] [int] NULL,
	[Total_ActiveUser] [int] NULL,
	[Total_GenCode] [int] NULL,
	[Total_CodeCheck] [int] NULL,
	[Total_Cash_Utilization] [decimal](18, 2) NULL,
	[Total_CashTransfer] [decimal](18, 2) NULL,
	[CreatedDate] [datetime] NULL,
	[Total_pending_Kyc] [int] NULL,
	[Total_Approved_Kyc] [int] NULL,
	[Total_Reject_Kyc] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
