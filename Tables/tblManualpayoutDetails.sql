/****** Object:  Table [dbo].[tblManualpayoutDetails]    Script Date: 3/2/2026 12:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblManualpayoutDetails](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[CompId] [varchar](30) NULL,
	[FilePath] [varchar](255) NULL,
	[RecordsIn] [int] NULL,
	[PayoutDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
