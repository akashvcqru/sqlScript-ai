/****** Object:  Table [dbo].[CityMaster_vcqru]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CityMaster_vcqru](
	[CityId] [int] IDENTITY(1,1) NOT NULL,
	[StateId] [int] NOT NULL,
	[CityName] [nvarchar](200) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [nvarchar](100) NULL,
	[UpdatedBy] [nvarchar](100) NULL,
	[CreatedAt] [datetime] NOT NULL,
	[UpdatedAt] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[CityId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
