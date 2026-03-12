/****** Object:  Table [dbo].[CompanyProduct]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CompanyProduct](
	[CompanyID] [int] IDENTITY(1,1) NOT NULL,
	[companyName] [nvarchar](200) NULL,
	[productName] [nvarchar](250) NULL,
	[expiryDate] [datetime] NULL,
	[employeeID] [varchar](25) NULL,
	[distributorID] [varchar](50) NULL,
	[code] [varchar](20) NULL,
	[otp] [varchar](5) NULL,
	[status] [bit] NULL,
	[MobileNumber] [varchar](15) NULL,
 CONSTRAINT [PK_CompanyProduct] PRIMARY KEY CLUSTERED 
(
	[CompanyID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
