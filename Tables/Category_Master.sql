/****** Object:  Table [dbo].[Category_Master]    Script Date: 3/2/2026 12:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Category_Master](
	[Row_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Category_ID] [nvarchar](50) NULL,
	[Category_Name] [nvarchar](50) NULL,
	[Entry_Date] [datetime] NULL,
	[Flag] [int] NULL,
 CONSTRAINT [PK__Category_Master__5E1FF51F] PRIMARY KEY CLUSTERED 
(
	[Row_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
