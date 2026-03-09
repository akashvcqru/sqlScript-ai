/****** Object:  Table [dbo].[StateMaster_vcqru]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StateMaster_vcqru](
	[StateId] [int] IDENTITY(1,1) NOT NULL,
	[StateName] [nvarchar](200) NOT NULL,
	[StateCode] [nvarchar](10) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [nvarchar](100) NULL,
	[UpdatedBy] [nvarchar](100) NULL,
	[CreatedAt] [datetime] NOT NULL,
	[UpdatedAt] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[StateId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
