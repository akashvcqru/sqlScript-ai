/****** Object:  Table [dbo].[CareersScreen]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CareersScreen](
	[Careersid] [int] IDENTITY(1,1) NOT NULL,
	[JobCategory] [int] NULL,
	[PreferredLocation] [nvarchar](100) NULL,
	[Availability] [int] NULL,
	[PositionApplyFor] [nvarchar](100) NULL,
	[ResumeName] [nvarchar](100) NULL,
	[ResumeName2] [nvarchar](100) NULL,
	[FullName] [nvarchar](50) NULL,
	[EmailAddress] [nvarchar](50) NULL,
	[YearsOfExp] [int] NULL,
	[Skills] [nvarchar](200) NULL,
	[Country] [nvarchar](50) NULL,
	[State] [nvarchar](50) NULL,
	[City] [nvarchar](50) NULL,
	[FindVcqru] [int] NULL,
	[Active] [bit] NULL,
	[CreatedDate] [datetime] NULL,
	[CreatedBy] [int] NULL,
 CONSTRAINT [PK_CareersScreen] PRIMARY KEY CLUSTERED 
(
	[Careersid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
