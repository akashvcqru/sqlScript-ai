/****** Object:  Table [dbo].[lot8pending]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[lot8pending](
	[SL NO#] [float] NULL,
	[Mobile_Number] [nvarchar](255) NULL,
	[Input] [float] NULL,
	[Employee Code] [nvarchar](255) NULL,
	[Techmaster ID] [nvarchar](255) NULL,
	[Mstar ID] [nvarchar](255) NULL,
	[RID] [nvarchar](255) NULL,
	[Mode of KYC] [nvarchar](255) NULL,
	[Dealer Code] [nvarchar](255) NULL,
	[State] [nvarchar](255) NULL,
	[Designation] [nvarchar](255) NULL,
	[Customer Name] [nvarchar](255) NULL,
	[Bank Name] [nvarchar](255) NULL,
	[Account holder Name] [nvarchar](255) NULL,
	[AccountNo] [nvarchar](255) NULL,
	[Ifsccode] [nvarchar](255) NULL,
	[Branch] [nvarchar](255) NULL,
	[City] [nvarchar](255) NULL,
	[Address] [nvarchar](255) NULL,
	[Adhar Card Number] [nvarchar](255) NULL,
	[PAN Number] [nvarchar](255) NULL,
	[YES/NO] [nvarchar](255) NULL,
	[Total Amount] [float] NULL,
	[1st LoT] [float] NULL,
	[2nd Lot] [float] NULL,
	[3rd Lot] [float] NULL,
	[4th Lot] [float] NULL,
	[5th Lot] [float] NULL,
	[6th Lot] [float] NULL,
	[7th Lot] [float] NULL,
	[Amount Payable 8th Lot] [float] NULL,
	[TDS Rate] [float] NULL,
	[TDS Deducted] [float] NULL,
	[Net Pay-out after TDS Deduct] [float] NULL,
	[TXN ID] [nvarchar](255) NULL,
	[Status] [nvarchar](255) NULL
) ON [PRIMARY]
GO
