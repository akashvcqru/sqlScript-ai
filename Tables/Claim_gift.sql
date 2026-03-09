/****** Object:  Table [dbo].[Claim_gift]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Claim_gift](
	[gift_id] [int] IDENTITY(1,1) NOT NULL,
	[Gift_name] [nvarchar](200) NULL,
	[Gift_value] [float] NULL,
	[Gift_desc] [nvarchar](max) NULL,
	[Gift_image] [nvarchar](200) NULL,
	[status] [int] NULL,
	[CompID] [varchar](100) NULL,
	[Gifts] [varchar](100) NULL,
	[UserType] [int] NULL,
	[Gift_point] [int] NULL,
	[Stage] [varchar](100) NULL,
	[Isdelete] [bit] NULL,
	[Brand_Code] [nvarchar](500) NULL,
	[IsCashConvertible] [bit] NULL,
	[CashType] [varchar](20) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
