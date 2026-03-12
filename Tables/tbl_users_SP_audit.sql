/****** Object:  Table [dbo].[tbl_users_SP_audit]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_users_SP_audit](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Mobile_Number] [nvarchar](50) NOT NULL,
	[UserName] [nvarchar](100) NULL,
	[District] [nvarchar](50) NULL,
	[StateName] [nvarchar](50) NULL,
	[Designation] [nvarchar](50) NULL,
	[Complete_Address] [nvarchar](500) NULL,
	[City] [nvarchar](50) NULL,
	[Pincode] [nvarchar](50) NULL,
	[Mechanic_Type] [int] NULL,
	[User_DOB] [datetime] NULL,
	[Gender] [varchar](20) NULL,
	[Marital_Status] [varchar](20) NULL,
	[User_Type] [varchar](50) NULL,
	[Head_Mechanic_Name] [varchar](100) NULL,
	[UserEmail] [nvarchar](50) NULL,
	[MappedCompid] [nvarchar](50) NULL,
	[UserPassword] [varchar](100) NULL,
	[IsActive] [int] NULL,
	[IsDelete] [int] NULL,
	[Remarks] [varchar](500) NULL,
	[Shopimg] [varchar](max) NULL,
	[Shopimg2] [varchar](500) NULL,
	[Shopimg3] [varchar](500) NULL,
	[Created_Date] [datetime] NULL,
	[Created_By] [varchar](50) NULL,
	[Updated_Date] [datetime] NULL,
	[Updated_By] [varchar](50) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
