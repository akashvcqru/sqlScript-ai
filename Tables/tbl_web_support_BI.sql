/****** Object:  Table [dbo].[tbl_web_support_BI]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_web_support_BI](
	[comp_id] [nvarchar](20) NULL,
	[enq_date] [date] NULL,
	[Pro_name] [nvarchar](100) NULL,
	[modeofenq] [nvarchar](100) NULL,
	[MobileNo] [nvarchar](20) NULL,
	[code1] [nvarchar](10) NULL,
	[code2] [nvarchar](10) NULL,
	[Completecode] [nvarchar](20) NOT NULL,
	[Status] [varchar](9) NOT NULL,
	[Amount_Won] [int] NULL,
	[ConsumerName] [nvarchar](150) NULL,
	[ConsumerCity] [nvarchar](50) NULL,
	[district] [nvarchar](40) NULL,
	[country] [nvarchar](30) NULL,
	[PinCode] [nvarchar](10) NULL,
	[Retailer_Name] [nvarchar](100) NULL,
	[ConsumerAddress] [nvarchar](500) NULL,
	[aadharNumber] [varchar](12) NULL,
	[Circle] [nvarchar](500) NULL,
	[Bank_Name] [varchar](70) NULL,
	[Account_HolderNm] [varchar](70) NULL,
	[Account_No] [nvarchar](50) NULL,
	[Branch] [nvarchar](max) NULL,
	[IFSC_Code] [nvarchar](50) NULL,
	[City] [nvarchar](max) NULL,
	[Account_Type] [nvarchar](50) NULL,
	[Address] [nvarchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
