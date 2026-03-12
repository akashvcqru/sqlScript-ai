/****** Object:  Table [dbo].[Enq_data]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Enq_data](
	[Row_ID] [int] IDENTITY(1,1) NOT NULL,
	[Code_ID] [int] NULL,
	[State] [varchar](200) NULL,
	[Pro_Name] [nvarchar](200) NULL,
	[MobileNo] [nvarchar](15) NULL,
	[Amount] [int] NULL,
	[De_Designation] [varchar](200) NULL,
	[Enq_Date] [datetime] NULL,
	[CompleteCode] [nvarchar](13) NULL,
	[Is_Success] [nvarchar](5) NULL,
	[Dial_Mode] [varchar](20) NULL,
	[DealerTechnicianId] [nvarchar](255) NULL,
	[DealerCode] [nvarchar](255) NULL,
	[D_State] [nvarchar](255) NULL,
	[ConsumerName] [nvarchar](255) NULL,
	[aadharFile] [nvarchar](255) NULL,
	[aadharback] [nvarchar](255) NULL,
	[Call_Status] [nvarchar](max) NULL,
	[Notes] [nvarchar](max) NULL,
	[Transaction_Status] [nvarchar](100) NULL,
	[chkPassbook] [nvarchar](255) NULL,
	[Bank_Name] [nvarchar](max) NULL,
	[Account_HolderNm] [nvarchar](max) NULL,
	[Account_No] [nvarchar](max) NULL,
	[IFSC_Code] [nvarchar](max) NULL,
	[Branch] [nvarchar](max) NULL,
	[City] [nvarchar](max) NULL,
	[Address] [nvarchar](max) NULL,
	[Remarks] [nvarchar](max) NULL,
	[aadharNumber] [nvarchar](100) NULL,
	[transctionNumber] [nvarchar](100) NULL,
	[Account_Type] [nvarchar](100) NULL,
	[Zone] [varchar](10) NULL,
	[Transaction_date] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
