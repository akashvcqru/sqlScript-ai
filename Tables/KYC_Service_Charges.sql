/****** Object:  Table [dbo].[KYC_Service_Charges]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[KYC_Service_Charges](
	[ServiceChargeID] [int] IDENTITY(1,1) NOT NULL,
	[CompanyID] [varchar](50) NULL,
	[KYCType] [varchar](50) NULL,
	[ChargeAmount] [decimal](10, 2) NULL,
	[CreatedDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[ServiceChargeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
