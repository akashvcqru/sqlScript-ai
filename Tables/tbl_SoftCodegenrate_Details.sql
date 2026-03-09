/****** Object:  Table [dbo].[tbl_SoftCodegenrate_Details]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_SoftCodegenrate_Details](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Pro_id] [varchar](10) NULL,
	[Comp_id] [varchar](20) NULL,
	[NOOfLabelRequest] [int] NULL,
	[Frequency] [int] NULL,
	[ProductRange] [varchar](100) NULL,
	[ProductQTY] [int] NULL,
	[Manufacture_date] [datetime] NULL,
	[TrackingId] [varchar](20) NULL,
	[Isactive] [bit] NULL,
	[Isdelete] [bit] NULL,
	[Remark] [varchar](100) NULL,
	[chkdiffrentpoint] [bit] NULL,
	[pointsdata] [nvarchar](500) NULL,
	[datefrom] [datetime] NULL,
	[dateto] [datetime] NULL,
	[MRP] [decimal](18, 0) NULL,
	[Entry_date] [datetime] NULL,
	[Isdefault] [bit] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
