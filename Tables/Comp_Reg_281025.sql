/****** Object:  Table [dbo].[Comp_Reg_281025]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Comp_Reg_281025](
	[Comp_ID] [nvarchar](50) NOT NULL,
	[Comp_Name] [nvarchar](50) NULL,
	[Comp_Cat_Id] [numeric](18, 0) NULL,
	[Comp_Email] [nvarchar](50) NULL,
	[WebSite] [nvarchar](50) NULL,
	[Address] [nvarchar](max) NULL,
	[City_ID] [numeric](18, 0) NULL,
	[Contact_Person] [nvarchar](50) NULL,
	[Mobile_No] [nvarchar](50) NULL,
	[Phone_No] [nvarchar](50) NULL,
	[Fax] [nvarchar](50) NULL,
	[Reg_Date] [datetime] NULL,
	[Password] [nvarchar](50) NULL,
	[Status] [numeric](18, 0) NULL,
	[Email_Vari_Flag] [numeric](18, 0) NULL,
	[Update_Flag] [numeric](18, 0) NULL,
	[Comp_Type] [nvarchar](50) NULL,
	[Upgrade_Date] [datetime] NULL,
	[Delete_Flag] [int] NULL,
	[IsRetailer] [int] NULL,
	[logo_path] [nvarchar](max) NULL,
	[ResiAddress] [nvarchar](255) NULL,
	[DirectorName] [nvarchar](55) NULL,
	[DirectorFatherName] [nvarchar](55) NULL,
	[AadharNumber] [varchar](12) NULL,
	[MinLimitAmount] [decimal](18, 2) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
