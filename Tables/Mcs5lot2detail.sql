/****** Object:  Table [dbo].[Mcs5lot2detail]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Mcs5lot2detail](
	[enquiry_date] [datetime] NULL,
	[product_name] [nvarchar](255) NULL,
	[completecode] [nvarchar](255) NULL,
	[status] [nvarchar](255) NULL,
	[Mobile_Number] [float] NULL,
	[amount_won] [float] NULL,
	[transaction_status] [nvarchar](255) NULL,
	[Redemption Date] [nvarchar](255) NULL,
	[TDS Applicable] [float] NULL,
	[mode_of_verification] [nvarchar](255) NULL,
	[technicianid] [float] NULL,
	[Validation 2] [nvarchar](255) NULL,
	[Validation3] [nvarchar](255) NULL,
	[Validation31] [nvarchar](255) NULL,
	[dealercode] [nvarchar](255) NULL,
	[Dealer State] [nvarchar](255) NULL,
	[designation] [nvarchar](255) NULL,
	[consumername] [nvarchar](255) NULL,
	[city] [nvarchar](255) NULL,
	[address] [nvarchar](255) NULL,
	[pincode] [float] NULL,
	[aadharnumber] [float] NULL,
	[bank_name] [nvarchar](255) NULL,
	[account_holder_name] [nvarchar](255) NULL,
	[Remark for payout] [nvarchar](255) NULL,
	[Redemption Status] [nvarchar](255) NULL
) ON [PRIMARY]
GO
