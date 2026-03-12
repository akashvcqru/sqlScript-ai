/****** Object:  Table [dbo].[claimKycForWebMVC]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[claimKycForWebMVC](
	[row_ID] [int] IDENTITY(1,1) NOT NULL,
	[Comp_ID] [nvarchar](50) NULL,
	[CompData] [nvarchar](max) NULL,
	[EKYCSelectedOptions] [nvarchar](max) NULL,
	[IsActive] [int] NULL,
	[IsDelete] [int] NULL,
	[Created_by] [varchar](max) NULL,
	[Created_Date] [datetime] NULL,
	[Updated_Date] [datetime] NULL,
	[Updated_by] [varchar](max) NULL,
	[kyc_Details] [nvarchar](max) NULL,
	[Claim_Settings] [nvarchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
