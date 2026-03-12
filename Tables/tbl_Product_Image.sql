/****** Object:  Table [dbo].[tbl_Product_Image]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_Product_Image](
	[PI_ID] [int] IDENTITY(1,1) NOT NULL,
	[Comp_ID] [varchar](20) NULL,
	[Pro_ID] [varchar](20) NULL,
	[Entry_date] [datetime] NULL,
	[Upper_View] [varchar](100) NULL,
	[Lower_View] [varchar](100) NULL,
	[Full_View] [varchar](100) NULL,
PRIMARY KEY CLUSTERED 
(
	[PI_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
