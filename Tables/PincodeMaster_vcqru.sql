/****** Object:  Table [dbo].[PincodeMaster_vcqru]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PincodeMaster_vcqru](
	[PincodeId] [int] IDENTITY(1,1) NOT NULL,
	[CityId] [int] NOT NULL,
	[Pincode] [nvarchar](10) NOT NULL,
	[AreaName] [nvarchar](200) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [nvarchar](100) NULL,
	[UpdatedBy] [nvarchar](100) NULL,
	[CreatedAt] [datetime] NOT NULL,
	[UpdatedAt] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[PincodeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
