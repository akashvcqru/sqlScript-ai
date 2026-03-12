/****** Object:  Table [dbo].[lot12$]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[lot12$](
	[enquiry_date] [datetime] NULL,
	[product_name] [nvarchar](255) NULL,
	[Scheme] [nvarchar](255) NULL,
	[completecode] [float] NULL,
	[status] [nvarchar](255) NULL,
	[Mobile Number] [float] NULL,
	[remarks] [nvarchar](255) NULL,
	[Active Status] [nvarchar](255) NULL,
	[amount_won] [float] NULL,
	[Payout Remark] [nvarchar](255) NULL,
	[Transaction Status] [nvarchar](255) NULL,
	[Transaction Remark] [nvarchar](255) NULL,
	[Transaction Date] [datetime] NULL,
	[Payout Approval Date] [datetime] NULL,
	[Pan Check Status] [nvarchar](255) NULL,
	[Applicable Tax rate] [nvarchar](255) NULL,
	[Deducted TDS] [nvarchar](255) NULL,
	[Net Paid] [float] NULL,
	[Pan Availability] [nvarchar](255) NULL,
	[Mode of Verification] [nvarchar](255) NULL,
	[technicianid] [float] NULL,
	[dealercode] [nvarchar](255) NULL,
	[DEALER STATE] [nvarchar](255) NULL,
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
