/****** Object:  Table [dbo].[pfl_Batchlist_temp_260226]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[pfl_Batchlist_temp_260226](
	[BatchListId] [int] IDENTITY(1,1) NOT NULL,
	[Date Of Mfg] [datetime] NULL,
	[Expire Date] [datetime] NULL,
	[SKU] [nvarchar](255) NULL,
	[Batch No] [nvarchar](255) NULL,
	[From] [nvarchar](255) NULL,
	[To] [nvarchar](255) NULL,
	[Total Use] [float] NULL,
	[Actual Spool Qty] [float] NULL,
	[Bal Qty] [float] NULL,
	[Diff QR V Prd] [nvarchar](255) NULL,
	[Remarks] [nvarchar](255) NULL,
	[RequestDate] [datetime] NULL,
	[AssignedBy] [nvarchar](100) NULL,
	[AssignRequestDate] [datetime] NULL,
	[RequestStatus] [varchar](15) NULL,
	[ApprovedBy] [nvarchar](100) NULL,
	[AttachmentPaths] [nvarchar](max) NULL,
	[UpdatedAt] [datetime] NULL,
	[UpdatedBy] [nvarchar](100) NULL,
	[DeletedBy] [nvarchar](100) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
