/****** Object:  Table [dbo].[tbl_CLaimfor]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_CLaimfor](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Comp_id] [varchar](100) NULL,
	[Is_cash] [bit] NULL,
	[Is_point] [bit] NULL,
	[Is_Both] [bit] NULL,
	[Is_Active] [bit] NULL,
	[Is_Delete] [bit] NULL,
	[Entry_date] [datetime] NULL,
	[Remark] [varchar](500) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
