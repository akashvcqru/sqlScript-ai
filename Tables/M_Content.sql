/****** Object:  Table [dbo].[M_Content]    Script Date: 3/2/2026 12:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[M_Content](
	[tbl_id] [numeric](18, 0) NOT NULL,
	[Menu_Heading] [nvarchar](300) NULL,
	[Menu_Content] [nvarchar](max) NULL,
	[Entry_Date] [datetime] NULL,
 CONSTRAINT [PK_M_Content] PRIMARY KEY CLUSTERED 
(
	[tbl_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
