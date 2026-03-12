/****** Object:  Table [dbo].['MCS5Lot-1to42$']    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].['MCS5Lot-1to42$'](
	[enquiry_date] [datetime] NULL,
	[product_name] [nvarchar](255) NULL,
	[Scheme] [nvarchar](255) NULL,
	[completecode] [float] NULL,
	[status] [nvarchar](255) NULL,
	[Mobile Number] [float] NULL,
	[remarks] [nvarchar](255) NULL,
	[Active_Status] [nvarchar](255) NULL,
	[amount_won] [float] NULL,
	[Payout_Remark] [nvarchar](255) NULL,
	[Transaction Status] [nvarchar](255) NULL,
	[PayStatus] [nvarchar](255) NULL,
	[Transaction Date] [datetime] NULL,
	[PayoutApprovalDate] [datetime] NULL,
	[PanCheckStatus] [nvarchar](255) NULL,
	[ApplicableTaxRate] [float] NULL,
	[DeductedTDS] [float] NULL,
	[NetPaid] [float] NULL,
	[PanAvailability] [nvarchar](255) NULL,
	[ModeofVerification] [nvarchar](255) NULL,
	[technicianid] [float] NULL,
	[dealercode] [nvarchar](255) NULL,
	[dealer_state] [nvarchar](255) NULL,
	[designation] [nvarchar](255) NULL,
	[consumername] [nvarchar](255) NULL,
	[pincode] [float] NULL,
	[aadharnumber] [float] NULL,
	[bank_name] [nvarchar](255) NULL,
	[account_holder_name] [nvarchar](255) NULL,
	[account_no] [nvarchar](255) NULL,
	[ifsc_code] [nvarchar](255) NULL,
	[branch] [nvarchar](255) NULL,
	[pancard_number] [nvarchar](255) NULL,
	[PanHolderName] [nvarchar](255) NULL
) ON [PRIMARY]
GO
