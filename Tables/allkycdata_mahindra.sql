/****** Object:  Table [dbo].[allkycdata_mahindra]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[allkycdata_mahindra](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[MobileNo] [bigint] NULL,
	[M_Consumerid] [int] NULL,
	[VRKbl_KYC_status] [nvarchar](50) NULL,
	[Call_Status] [nvarchar](100) NULL,
	[Notes] [nvarchar](max) NULL,
	[TechnicianID] [nvarchar](50) NULL,
	[DealerCode] [nvarchar](50) NULL,
	[consumername] [nvarchar](200) NULL,
	[city] [nvarchar](100) NULL,
	[Address] [nvarchar](max) NULL,
	[pincode] [nvarchar](20) NULL,
	[aadharnumber] [nvarchar](20) NULL,
	[CreatedDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
