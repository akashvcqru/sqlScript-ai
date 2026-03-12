/****** Object:  Table [dbo].[temp_report]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[temp_report](
	[enquiry_date] [datetime] NULL,
	[product_name] [nvarchar](255) NULL,
	[code1] [nvarchar](255) NULL,
	[code2] [nvarchar](255) NULL,
	[completecode] [nvarchar](255) NULL,
	[status] [nvarchar](255) NULL,
	[mobile_number] [nvarchar](255) NULL,
	[remarks] [nvarchar](255) NULL,
	[Village] [nvarchar](255) NULL,
	[District] [nvarchar](255) NULL,
	[Verified State] [nvarchar](255) NULL,
	[Pack Name] [nvarchar](255) NULL,
	[Dealership Name] [nvarchar](255) NULL,
	[Dealership Location] [nvarchar](255) NULL,
	[Comments] [nvarchar](255) NULL,
	[Consumer_Name] [nvarchar](255) NULL,
	[mode_of_verification] [nvarchar](255) NULL,
	[VCQRU Location] [nvarchar](255) NULL
) ON [PRIMARY]
GO
