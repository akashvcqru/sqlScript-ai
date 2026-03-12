/****** Object:  Table [dbo].[tbl_UPIVerificationdata]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_UPIVerificationdata](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[M_Consumer_id] [int] NULL,
	[Mobileno] [nvarchar](13) NULL,
	[UPIID] [nvarchar](100) NULL,
	[Status] [nvarchar](100) NULL,
	[ResponseCode] [nvarchar](10) NULL,
	[Responsemsg] [nvarchar](100) NULL,
	[Benificiryname] [nvarchar](100) NULL,
	[RequestDate] [datetime] NULL,
	[Remarks] [nvarchar](500) NULL,
	[APIResponsedata] [nvarchar](max) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
