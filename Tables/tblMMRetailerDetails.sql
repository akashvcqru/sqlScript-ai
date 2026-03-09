/****** Object:  Table [dbo].[tblMMRetailerDetails]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblMMRetailerDetails](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[RetailerId] [varchar](30) NULL,
	[ShopName] [varchar](40) NULL,
	[Pincode] [char](6) NULL,
	[City] [varchar](40) NULL,
	[State] [varchar](40) NULL,
	[DealerName] [varchar](40) NULL,
	[DealerCode] [varchar](40) NULL,
	[Status] [bit] NULL,
	[ReqDate] [datetime] NULL,
	[M_Consumerid] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
