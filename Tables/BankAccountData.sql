/****** Object:  Table [dbo].[BankAccountData]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BankAccountData](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[M_Consumerid] [varchar](50) NULL,
	[Account_HolderNm] [varchar](150) NULL,
	[Account_No] [varchar](50) NULL,
	[IFSC_Code] [varchar](20) NULL,
	[CreatedDate] [datetime] NULL,
	[MobileNo] [varchar](15) NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
