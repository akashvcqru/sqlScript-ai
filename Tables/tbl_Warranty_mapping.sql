/****** Object:  Table [dbo].[tbl_Warranty_mapping]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_Warranty_mapping](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[MobileNo] [varchar](15) NULL,
	[OldCode] [varchar](15) NULL,
	[NewCode] [varchar](15) NULL,
	[OldUniqueDeviceId] [nvarchar](500) NULL,
	[NewUniqueDeviceId] [nvarchar](500) NULL,
	[MappingDate] [datetime] NULL,
	[IsActive] [bit] NULL,
	[IsDelete] [bit] NULL,
	[Remark] [nvarchar](500) NULL,
	[Oldcodeid] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
