/****** Object:  Table [dbo].[tbl_Industry_Type]    Script Date: 5/25/2026 3:55:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_Industry_Type](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Industry_Type] [nvarchar](100) NOT NULL UNIQUE,
	[IsActive] [bit] NOT NULL CONSTRAINT [DF_tbl_Industry_Type_IsActive] DEFAULT ((1)),
	[CreatedAt] [datetime] NOT NULL CONSTRAINT [DF_tbl_Industry_Type_CreatedAt] DEFAULT (getdate()),
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
