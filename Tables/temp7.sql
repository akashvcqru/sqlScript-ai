/****** Object:  Table [dbo].[temp7]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[temp7](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[enquiry_date] [datetime] NULL,
	[product_name] [nvarchar](255) NULL,
	[completecode] [float] NULL,
	[status] [nvarchar](255) NULL,
	[Mobile_Number] [float] NULL,
	[remarks] [nvarchar](255) NULL,
	[amount_won] [float] NULL,
	[transaction_status] [nvarchar](255) NULL,
	[mode_of_verification] [nvarchar](255) NULL,
	[technicianid] [float] NULL,
	[dealercode] [nvarchar](255) NULL,
	[dealer_state] [nvarchar](255) NULL,
	[designation] [nvarchar](255) NULL,
	[consumername] [nvarchar](255) NULL,
	[city] [nvarchar](255) NULL,
	[address] [nvarchar](255) NULL,
	[pincode] [float] NULL,
	[aadharnumber] [float] NULL,
	[bank_name] [nvarchar](255) NULL,
	[account_holder_name] [nvarchar](255) NULL,
	[account_no] [nvarchar](255) NULL,
	[ifsc_code] [nvarchar](255) NULL,
	[branch] [nvarchar](255) NULL,
	[city_of_branch] [nvarchar](255) NULL,
	[br_address] [nvarchar](255) NULL,
	[CreatedAt] [datetime2](7) NULL,
	[UpdatedAt] [date] NULL,
	[Comp_Id] [nvarchar](15) NULL
) ON [PRIMARY]
GO
