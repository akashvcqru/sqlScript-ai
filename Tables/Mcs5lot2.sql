/****** Object:  Table [dbo].[Mcs5lot2]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Mcs5lot2](
	[SL NO#] [float] NULL,
	[Mobile_Number] [nvarchar](255) NULL,
	[Last Input] [float] NULL,
	[Last Date of Coupon Verified] [datetime] NULL,
	[Employee Code] [nvarchar](255) NULL,
	[Techmaster ID] [nvarchar](255) NULL,
	[Mstar ID] [float] NULL,
	[RID] [nvarchar](255) NULL,
	[ID Status ] [nvarchar](255) NULL,
	[Mode of KYC] [nvarchar](255) NULL,
	[Dealer Code] [nvarchar](255) NULL,
	[State] [nvarchar](255) NULL,
	[Designation] [nvarchar](255) NULL,
	[Name as per ID] [nvarchar](255) NULL,
	[Name as per Aadhar] [nvarchar](255) NULL,
	[Match in ID and Aadhar] [bit] NOT NULL,
	[Bank Name] [nvarchar](255) NULL,
	[Name as per Bank] [nvarchar](255) NULL,
	[Match as per aadhar and bank] [bit] NOT NULL,
	[Comments] [nvarchar](255) NULL,
	[AccountNo] [nvarchar](255) NULL,
	[Ifsccode] [nvarchar](255) NULL,
	[Branch] [nvarchar](255) NULL,
	[City] [nvarchar](255) NULL,
	[Address] [nvarchar](255) NULL,
	[Adhar Card Number] [float] NULL,
	[Name as per PAN] [nvarchar](255) NULL,
	[Match as per Pan and bank] [bit] NOT NULL,
	[PAN Card ] [nvarchar](255) NULL,
	[Total Amount Won] [float] NULL,
	[Lot 1] [float] NULL,
	[Lot 2] [float] NULL,
	[TDS Deduction] [float] NULL,
	[TDS Deducted] [float] NULL,
	[Final Amount] [float] NULL,
	[VCQRU Remark for Payment as on 23rd May 24] [nvarchar](255) NULL,
	[TXN Date & Time] [nvarchar](255) NULL,
	[TXN ID] [nvarchar](255) NULL,
	[Payment Status] [nvarchar](255) NULL
) ON [PRIMARY]
GO
