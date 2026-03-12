/****** Object:  Table [dbo].[mahindraCodeCheckData]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[mahindraCodeCheckData](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[InsertedDate] [datetime] NOT NULL,
	[enquiry_date] [datetime] NULL,
	[product_name] [nvarchar](200) NULL,
	[completecode] [nvarchar](200) NULL,
	[status] [nvarchar](50) NULL,
	[Mobile_Number] [nvarchar](20) NULL,
	[remarks] [nvarchar](max) NULL,
	[amount_won] [decimal](18, 2) NULL,
	[transaction_status] [nvarchar](50) NULL,
	[mode_of_verification] [nvarchar](50) NULL,
	[technicianid] [nvarchar](50) NULL,
	[dealercode] [nvarchar](50) NULL,
	[dealer_state] [nvarchar](100) NULL,
	[designation] [nvarchar](200) NULL,
	[consumername] [nvarchar](200) NULL,
	[city] [nvarchar](100) NULL,
	[address] [nvarchar](max) NULL,
	[pincode] [nvarchar](20) NULL,
	[aadharnumber] [nvarchar](20) NULL,
	[bank_name] [nvarchar](200) NULL,
	[account_holder_name] [nvarchar](200) NULL,
	[account_no] [nvarchar](100) NULL,
	[ifsc_code] [nvarchar](20) NULL,
	[branch] [nvarchar](300) NULL,
	[city_of_branch] [nvarchar](100) NULL,
	[br_address] [nvarchar](max) NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
