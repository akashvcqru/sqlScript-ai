/****** Object:  Table [dbo].[T_Album_Image]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Album_Image](
	[Tbl_Id] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[Album_Id] [nvarchar](50) NULL,
	[Image_Name] [nvarchar](200) NULL
) ON [PRIMARY]
GO
