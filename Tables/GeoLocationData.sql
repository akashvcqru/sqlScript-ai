/****** Object:  Table [dbo].[GeoLocationData]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GeoLocationData](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Comp_Id] [varchar](50) NULL,
	[MobileNo] [varchar](20) NULL,
	[Latitude] [varchar](50) NULL,
	[Longitude] [varchar](50) NULL,
	[Amenity] [nvarchar](200) NULL,
	[Road] [nvarchar](200) NULL,
	[Suburb] [nvarchar](200) NULL,
	[City] [nvarchar](200) NULL,
	[County] [nvarchar](200) NULL,
	[StateDistrict] [nvarchar](200) NULL,
	[State] [nvarchar](200) NULL,
	[Postcode] [nvarchar](10) NULL,
	[Country] [nvarchar](100) NULL,
	[CountryCode] [nvarchar](10) NULL,
	[CreatedOn] [datetime] NULL,
	[DisplayName] [nvarchar](500) NULL,
	[Town] [nvarchar](200) NULL,
	[Enq_Date] [datetime] NULL,
	[Code1] [nvarchar](10) NULL,
	[Code2] [nvarchar](16) NULL,
	[Updated_Date] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
