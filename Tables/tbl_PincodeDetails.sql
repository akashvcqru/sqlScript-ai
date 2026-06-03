/****** Object:  Table [dbo].[tbl_PincodeDetails]    Script Date: 5/25/2026 2:00:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_PincodeDetails](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Pincode] [varchar](10) NOT NULL UNIQUE,
	[State] [nvarchar](100) NULL,
	[City] [nvarchar](100) NULL,
	[CreatedAt] [datetime] NOT NULL CONSTRAINT [DF_tbl_PincodeDetails_CreatedAt] DEFAULT (getdate()),
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
