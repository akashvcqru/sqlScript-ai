/****** Object:  Table [dbo].[tbl_citywisepoint]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_citywisepoint](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[city_name] [varchar](100) NULL,
	[point] [numeric](10, 2) NULL,
	[comp_id] [varchar](50) NULL,
	[status] [int] NULL,
	[createddate] [datetime] NULL,
	[pro_id] [varchar](15) NULL,
	[state_id] [varchar](10) NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
