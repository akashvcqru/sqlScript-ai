/****** Object:  Table [dbo].[tbl_supportbkp]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_supportbkp](
	[Enquiry_Date] [datetime] NULL,
	[Vendor] [nvarchar](500) NULL,
	[Product_Name] [nvarchar](500) NULL,
	[Location] [nvarchar](500) NULL,
	[Code1] [nvarchar](50) NULL,
	[Code2] [nvarchar](50) NULL,
	[Status] [varchar](500) NOT NULL,
	[email] [nvarchar](500) NULL,
	[Mobile_Number] [nvarchar](15) NULL,
	[Amount_Won] [varchar](50) NOT NULL,
	[Mode_of_Verification] [nvarchar](500) NULL,
	[TechnicianID] [varchar](200) NULL,
	[DealerCode] [varchar](200) NULL,
	[consumername] [nvarchar](150) NULL,
	[city] [nvarchar](500) NULL,
	[Address] [nvarchar](4000) NULL,
	[pincode] [nvarchar](10) NULL,
	[aadharnumber] [varchar](12) NULL,
	[Bank_Name] [nvarchar](max) NULL,
	[Account_holder_Name] [nvarchar](max) NULL,
	[Account_No] [nvarchar](50) NULL,
	[Branch] [nvarchar](max) NULL,
	[IFSC_Code] [nvarchar](50) NULL,
	[City_of_Branch] [nvarchar](max) NULL,
	[Branch_Address] [nvarchar](max) NULL,
	[Account_type] [nvarchar](50) NULL,
	[Notes] [varchar](max) NOT NULL,
	[CreatedDate] [datetime] NULL,
	[CreatedBy] [varchar](200) NULL,
	[UpdatedDate] [datetime] NULL,
	[UpdatedBy] [varchar](200) NULL,
	[Call_Status] [varchar](200) NULL,
	[Id] [int] IDENTITY(1,1) NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
