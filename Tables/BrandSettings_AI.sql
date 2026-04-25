USE [VCQRU_Dev]; -- Update with correct DB name if needed
GO

CREATE TABLE [dbo].[BrandSettings_AI](
	[row_ID] [int] IDENTITY(1,1) NOT NULL,
	[Comp_ID] [nvarchar](100) NULL,
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
	[InvoiceAmountPercentage] [decimal](18, 2) NULL,
 CONSTRAINT [PK__BrandSet_AI] PRIMARY KEY CLUSTERED 
(
	[row_ID] ASC
)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[BrandSettings_AI] ADD  DEFAULT ((0)) FOR [isLeaderboardreqired]
GO
