/****** Object:  Table [dbo].[M_BankAccount_nullvalue]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_BankAccount_nullvalue](
	[Row_ID] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[Bank_ID] [nvarchar](50) NOT NULL,
	[Bank_Name] [nvarchar](max) NULL,
	[Account_HolderNm] [nvarchar](max) NULL,
	[Account_No] [nvarchar](50) NULL,
	[Branch] [nvarchar](max) NULL,
	[IFSC_Code] [nvarchar](50) NULL,
	[City] [nvarchar](max) NULL,
	[RTGS_Code] [nvarchar](50) NULL,
	[Account_Type] [nvarchar](50) NULL,
	[Address] [nvarchar](max) NULL,
	[Entry_Date] [datetime] NULL,
	[Flag] [int] NULL,
	[M_Consumerid] [int] NULL,
	[Comp_id] [nvarchar](50) NULL,
	[chkPassbook] [varchar](max) NULL,
	[psbUploadedate] [datetime] NULL,
	[psbUploadedBy] [nvarchar](50) NULL,
	[passbook_source] [nvarchar](50) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
