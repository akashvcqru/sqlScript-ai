/****** Object:  Table [dbo].[dealership_details]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dealership_details](
	[ID] [float] NULL,
	[Dealer Code] [nvarchar](255) NULL,
	[Dealer Name] [nvarchar](255) NULL,
	[Category] [nvarchar](255) NULL,
	[Location] [nvarchar](255) NULL,
	[District] [nvarchar](255) NULL,
	[State] [nvarchar](255) NULL,
	[Zone] [nvarchar](255) NULL,
	[Landmark] [nvarchar](255) NULL,
	[City] [nvarchar](255) NULL,
	[village] [nvarchar](255) NULL,
	[pincode] [nvarchar](255) NULL,
	[email_id] [nvarchar](255) NULL,
	[aadhar] [nvarchar](15) NULL,
	[MOBILENO] [varchar](13) NULL,
	[Created_Date] [datetime] NULL
) ON [PRIMARY]
GO
