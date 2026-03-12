/****** Object:  Table [dbo].[MenuCompanyAccess]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MenuCompanyAccess](
	[MenuCompanyAccess_Id] [int] IDENTITY(1,1) NOT NULL,
	[MenuId] [int] NOT NULL,
	[CompanyId] [nvarchar](50) NOT NULL,
	[AccessType] [nvarchar](20) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[MenuCompanyAccess_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
