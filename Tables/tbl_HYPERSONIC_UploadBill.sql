/****** Object:  Table [dbo].[tbl_HYPERSONIC_UploadBill]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_HYPERSONIC_UploadBill](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[M_Consumerid] [int] NULL,
	[MobileNo] [nvarchar](13) NULL,
	[Code1] [int] NULL,
	[Code2] [int] NULL,
	[BillPath] [nvarchar](500) NULL,
	[Entry_date] [datetime] NULL,
	[Isactive] [bit] NULL,
	[Isdelete] [bit] NULL,
	[Remark] [nvarchar](500) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
