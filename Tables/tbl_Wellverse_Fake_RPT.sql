/****** Object:  Table [dbo].[tbl_Wellverse_Fake_RPT]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_Wellverse_Fake_RPT](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Mobileno] [nvarchar](12) NULL,
	[Imgpath] [nvarchar](max) NULL,
	[Purchasedfrom] [nvarchar](100) NULL,
	[Lat] [nvarchar](100) NULL,
	[Long] [nvarchar](100) NULL,
	[Address] [nvarchar](max) NULL,
	[City] [nvarchar](100) NULL,
	[State] [nvarchar](100) NULL,
	[Country] [nvarchar](100) NULL,
	[Comp_id] [nvarchar](20) NULL,
	[Remark] [nvarchar](max) NULL,
	[Dateofreport] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
