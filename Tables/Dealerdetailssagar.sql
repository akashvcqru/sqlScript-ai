/****** Object:  Table [dbo].[Dealerdetailssagar]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Dealerdetailssagar](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Dealer Code] [nvarchar](255) NULL,
	[Dealer Name] [nvarchar](255) NULL,
	[Category] [nvarchar](255) NULL,
	[Location] [nvarchar](255) NULL,
	[District] [nvarchar](255) NULL,
	[State] [nvarchar](255) NULL,
	[Zone] [nvarchar](255) NULL,
	[Landmark] [nvarchar](max) NULL,
	[City] [varchar](50) NULL,
	[village] [varchar](100) NULL,
	[pincode] [varchar](10) NULL,
	[email_id] [nvarchar](150) NULL,
	[MOBILENO] [varchar](13) NULL,
	[Created_Date] [datetime] NULL,
	[Comp_ID] [nvarchar](10) NULL,
	[Isactive] [bit] NULL,
	[Isdelete] [bit] NULL,
	[Remark] [varchar](500) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
