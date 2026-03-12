/****** Object:  Table [dbo].[AkemiLoyaltyData]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AkemiLoyaltyData](
	[Claim_id] [float] NULL,
	[Claim_date] [datetime] NULL,
	[Mobileno] [nvarchar](255) NULL,
	[Amount] [float] NULL,
	[PointsValue] [float] NULL,
	[ConsumerName] [nvarchar](255) NULL,
	[City] [nvarchar](255) NULL,
	[document_status] [nvarchar](255) NULL,
	[action_date] [nvarchar](255) NULL,
	[vendor_Status] [nvarchar](255) NULL,
	[comp_id] [nvarchar](255) NULL,
	[vendor_comment] [nvarchar](255) NULL,
	[Gifts_Redeemed] [nvarchar](255) NULL,
	[Points_Redeemed] [nvarchar](255) NULL,
	[UPIID] [nvarchar](255) NULL,
	[PaymentStatus] [nvarchar](255) NULL,
	[BankRefID] [nvarchar](255) NULL,
	[TransactionDate] [datetime] NULL,
	[PaymentRemarks] [nvarchar](255) NULL,
	[Account_No] [nvarchar](255) NULL,
	[Account_HolderNm] [nvarchar](255) NULL,
	[Bank_Name] [nvarchar](255) NULL,
	[IFSC_Code] [nvarchar](255) NULL
) ON [PRIMARY]
GO
