/****** Object:  Table [dbo].[WarrentyDetails]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WarrentyDetails](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[BillNo] [nvarchar](50) NULL,
	[PurchaseDate] [datetime] NULL,
	[Email] [nvarchar](50) NULL,
	[Mobile] [nvarchar](20) NULL,
	[WarrantyPeriod] [varchar](50) NULL,
	[ExpirationDate] [datetime] NULL,
	[IsWarrantyClaimed] [int] NULL,
	[ImagePath] [nvarchar](400) NULL,
	[Comment] [nvarchar](500) NULL,
	[ImagePathBill] [nvarchar](200) NULL,
	[VendorClaimStatus] [varchar](20) NULL,
	[VendorComments] [varchar](500) NULL,
	[Code] [varchar](20) NULL,
	[claimdate] [datetime] NULL,
	[State] [nvarchar](max) NULL,
	[City] [nvarchar](max) NULL,
	[DealerName] [nvarchar](max) NULL,
	[Uniquedeviceid] [varchar](70) NULL,
	[Serialno] [varchar](100) NULL,
	[PurchaseFrom] [varchar](50) NULL,
	[Battary_volt] [varchar](20) NULL,
	[Brand] [varchar](200) NULL,
	[Ratting] [varchar](10) NULL,
	[Pincode] [varchar](15) NULL,
	[Address] [nvarchar](150) NULL,
	[Model] [nvarchar](50) NULL,
	[batryType] [varchar](50) NULL,
	[OldSerialno] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
