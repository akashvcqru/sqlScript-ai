/****** Object:  Table [dbo].[M_Consumer_new]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_Consumer_new](
	[M_Consumerid] [int] IDENTITY(1,1) NOT NULL,
	[User_ID] [nvarchar](50) NOT NULL,
	[ConsumerName] [nvarchar](150) NULL,
	[Email] [nvarchar](150) NULL,
	[MobileNo] [nvarchar](15) NULL,
	[City] [nvarchar](50) NULL,
	[PinCode] [nvarchar](10) NULL,
	[Password] [nvarchar](50) NULL,
	[Entry_Date] [datetime] NULL,
	[IsActive] [int] NULL,
	[IsDelete] [int] NULL,
	[Address] [nvarchar](500) NULL,
	[ReferralCode] [numeric](20, 0) NULL,
	[IsSharedReferralCode] [bit] NULL,
	[employeeID] [varchar](20) NULL,
	[distributorID] [varchar](20) NULL,
	[aadharNumber] [varchar](12) NULL,
	[aadharFile] [varchar](1000) NULL,
	[aadharback] [varchar](1000) NULL,
	[aadharUploadedate] [datetime] NULL,
	[aadharUploadedBy] [nvarchar](50) NULL,
	[Aadhar_source] [nvarchar](50) NULL,
 CONSTRAINT [PK_M_Consumer] PRIMARY KEY CLUSTERED 
(
	[M_Consumerid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
