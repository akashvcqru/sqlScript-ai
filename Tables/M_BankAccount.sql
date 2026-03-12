/****** Object:  Table [dbo].[M_BankAccount]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_BankAccount](
	[Row_ID] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[Bank_ID] [nvarchar](50) NOT NULL,
	[Bank_Name] [varchar](70) NULL,
	[Account_HolderNm] [varchar](70) NULL,
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
	[chkPassbook] [varchar](150) NULL,
	[psbUploadedate] [datetime] NULL,
	[psbUploadedBy] [nvarchar](50) NULL,
	[passbook_source] [nvarchar](50) NULL,
	[TNC] [bit] NULL,
 CONSTRAINT [PK__M_BankAccount__47A6A41B] PRIMARY KEY CLUSTERED 
(
	[Row_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
