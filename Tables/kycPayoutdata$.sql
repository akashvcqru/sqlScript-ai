/****** Object:  Table [dbo].[kycPayoutdata$]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[kycPayoutdata$](
	[S#N] [float] NULL,
	[USER NUMBER] [float] NULL,
	[STATE] [nvarchar](255) NULL,
	[DESIGNATION] [nvarchar](255) NULL,
	[NAME AS PER AADHAR] [nvarchar](255) NULL,
	[BANK NAME] [nvarchar](255) NULL,
	[NAME AS PER BANK] [nvarchar](255) NULL,
	[ACCOUNTNO] [nvarchar](255) NULL,
	[IFSCCODE] [nvarchar](255) NULL,
	[BRANCH] [nvarchar](255) NULL,
	[ADHAR CARD NUMBER] [float] NULL,
	[PAN CARD ] [nvarchar](255) NULL,
	[NAME AS PER PAN] [nvarchar](255) NULL
) ON [PRIMARY]
GO
