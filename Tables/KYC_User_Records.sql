/****** Object:  Table [dbo].[KYC_User_Records]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[KYC_User_Records](
	[UserKYCID] [int] IDENTITY(1,1) NOT NULL,
	[M_ConsumerID] [int] NULL,
	[KYC_Service_Charges_ID] [int] NULL,
	[KYCStatus] [varchar](20) NULL,
	[CreatedDate] [datetime] NULL,
	[KYCCount] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[UserKYCID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
