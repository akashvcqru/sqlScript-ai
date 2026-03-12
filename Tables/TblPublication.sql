/****** Object:  Table [dbo].[TblPublication]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TblPublication](
	[Row_Id] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[M_Consumerid] [int] NULL,
	[Bookname] [nvarchar](255) NULL,
	[bookShop] [nvarchar](max) NULL,
	[ccenter] [nvarchar](max) NULL,
	[CreatedDate] [datetime] NULL,
	[UpdatedDate] [datetime] NULL,
	[Code1] [varchar](5) NULL,
	[Code2] [varchar](8) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
