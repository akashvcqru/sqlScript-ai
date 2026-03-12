/****** Object:  Table [dbo].[Awards_Dispatch_Master]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Awards_Dispatch_Master](
	[RowId] [bigint] IDENTITY(1,1) NOT NULL,
	[Courier_ID] [nvarchar](50) NULL,
	[Comp_ID] [nvarchar](50) NULL,
	[Tracking_No] [nvarchar](50) NULL,
	[Dispatch_Date] [datetime] NULL,
	[Expected_Date] [datetime] NULL,
	[Dispatch_Location] [nvarchar](500) NULL,
	[Courier_Status] [int] NULL,
	[Entry_Date] [datetime] NULL,
	[Received_Date] [datetime] NULL,
	[Received_Flag] [int] NULL,
	[Admin_Reason] [nvarchar](500) NULL,
	[Consumer_Reason] [nvarchar](500) NULL,
PRIMARY KEY CLUSTERED 
(
	[RowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
