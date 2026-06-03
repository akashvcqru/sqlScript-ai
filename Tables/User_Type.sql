/****** Object:  Table [dbo].[User_Type]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[User_Type](
	[Row_ID] [int] IDENTITY(1,1) NOT NULL,
	[UserID] [varchar](20) NULL,
	[User_Type] [varchar](max) NULL,
	[Comp_ID] [varchar](20) NULL,
	[IsActive] [int] NULL,
	[IsDeleted] [int] NULL,
	[Create_Date] [datetime] NULL,
	[CanScanCoupon] [bit] NULL,
	[CanGetsBenefit] [bit] NULL,
	[canregisterbyapp] [int] NULL,
	[CanregisterOtheruser] [nvarchar](max) NULL,
	[Level] [int] NOT NULL,
	[Brand_Code] [varchar](500) NULL,
	[ScanPriority] [bit] NULL,
	[ProductMapped] [varchar](100) NULL,
	[CanSeePoints] [bit] NOT NULL,
	[isClaimTypeDealer] [bit] NOT NULL,
	[isNeedsDealer] [bit] NOT NULL,
	[IsSupervisorApprovalRequired] [bit] NULL,
	[SupervisorValue] [decimal](18, 2) NULL,
	[SupervisorGet] [varchar](50) NULL,
	[SupervisorValueType] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[Row_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
