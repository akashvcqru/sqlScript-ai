/****** Object:  Table [dbo].[BrandSettings]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BrandSettings](
	[row_ID] [int] IDENTITY(1,1) NOT NULL,
	[Comp_ID] [nvarchar](50) NULL,
	[CompData] [nvarchar](max) NULL,
	[RegistrationFields] [nvarchar](max) NULL,
	[EKYCSelectedOptions] [nvarchar](max) NULL,
	[IsActive] [int] NULL,
	[IsDelete] [int] NULL,
	[Created_by] [varchar](max) NULL,
	[Created_Date] [datetime] NULL,
	[Updated_Date] [datetime] NULL,
	[Updated_by] [varchar](max) NULL,
	[kyc_Details] [nvarchar](max) NULL,
	[Claim_Settings] [nvarchar](max) NULL,
	[profilesettings] [nvarchar](max) NULL,
	[Introdata] [nvarchar](max) NULL,
	[DashboardIcons] [nvarchar](max) NULL,
	[Blogs] [nvarchar](max) NULL,
	[helpandsupport] [nvarchar](max) NULL,
	[FAQ] [nvarchar](max) NULL,
	[Reffral] [nvarchar](max) NULL,
	[RefferalContaints] [nvarchar](max) NULL,
	[Socialmedia] [nvarchar](max) NULL,
	[ProfileIcons] [nvarchar](max) NULL,
	[Dashboardtextname] [nvarchar](max) NULL,
	[ClaimDetails] [nvarchar](max) NULL,
	[ContactUsContains] [nvarchar](max) NULL,
	[isLeaderboardreqired] [bit] NULL,
	[Refraltagline] [nvarchar](max) NULL,
	[Multiuserregistrationfield] [nvarchar](max) NULL,
	[Dashboardiconsmultiuser] [nvarchar](max) NULL,
PRIMARY KEY CLUSTERED 
(
	[row_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
