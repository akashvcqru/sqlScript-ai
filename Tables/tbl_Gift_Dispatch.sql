/****** Object:  Table [dbo].[tbl_Gift_Dispatch]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_Gift_Dispatch](
	[Row_ID] [int] IDENTITY(1,1) NOT NULL,
	[M_consumerID] [int] NULL,
	[Gift_Name] [varchar](max) NULL,
	[DispatchDate] [datetime] NULL,
	[CreatedDate] [datetime] NULL,
	[Mobile_No] [nvarchar](10) NULL,
	[Comp_ID] [varchar](20) NULL,
	[Courier_Name] [varchar](100) NULL,
	[Tracking_No] [varchar](50) NULL,
	[Dispatch_location] [varchar](max) NULL,
	[Comments] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
