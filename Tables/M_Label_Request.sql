/****** Object:  Table [dbo].[M_Label_Request]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_Label_Request](
	[Row_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Pro_ID] [nvarchar](50) NULL,
	[Qty] [numeric](18, 0) NULL,
	[Label_Code] [nvarchar](50) NULL,
	[Request_Price] [numeric](18, 2) NULL,
	[Price] [numeric](18, 2) NULL,
	[Entry_Date] [datetime] NULL,
	[Flag] [int] NULL,
	[Tracking_No] [nvarchar](max) NULL,
	[LabelRequestId] [nvarchar](max) NULL,
	[ProductioUnit] [int] NULL,
	[Channels] [int] NULL,
 CONSTRAINT [PK_M_Label_Request] PRIMARY KEY CLUSTERED 
(
	[Row_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
