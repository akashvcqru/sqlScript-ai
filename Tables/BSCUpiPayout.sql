/****** Object:  Table [dbo].[BSCUpiPayout]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BSCUpiPayout](
	[Enquiry Date] [datetime] NULL,
	[Product Name] [nvarchar](255) NULL,
	[Enquiry Mode] [nvarchar](255) NULL,
	[Mobile Number] [nvarchar](255) NULL,
	[Complete Code] [nvarchar](255) NULL,
	[CodeCheckStatus] [nvarchar](255) NULL,
	[Amount] [float] NULL,
	[Transaction Status] [nvarchar](255) NULL,
	[Remarks] [nvarchar](255) NULL,
	[Transaction id] [nvarchar](255) NULL,
	[Date] [datetime] NULL
) ON [PRIMARY]
GO
