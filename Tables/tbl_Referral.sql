/****** Object:  Table [dbo].[tbl_Referral]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_Referral](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ReferralMobileNo] [nvarchar](15) NULL,
	[Remarks] [nvarchar](100) NULL,
	[IsActive] [int] NULL,
	[IsDelete] [int] NULL,
	[Created_by] [varchar](100) NULL,
	[Created_Date] [datetime] NULL,
	[Updated_by] [varchar](100) NULL,
	[Updated_Date] [datetime] NULL,
	[ref_code] [varchar](50) NULL,
	[PointReferral] [int] NULL,
	[Comp_ID] [nvarchar](150) NULL,
	[UseCount] [bit] NULL
) ON [PRIMARY]
GO
