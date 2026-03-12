/****** Object:  Table [dbo].[tbl_pointmultiplier]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_pointmultiplier](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Comp_Id] [varchar](50) NOT NULL,
	[IsActive] [bit] NULL,
	[CodeScanCount] [int] NULL,
	[ExtraPoint] [decimal](5, 2) NULL,
	[Create_Date] [datetime] NULL,
	[User_Type] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
