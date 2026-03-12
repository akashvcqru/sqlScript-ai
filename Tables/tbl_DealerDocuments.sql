/****** Object:  Table [dbo].[tbl_DealerDocuments]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_DealerDocuments](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[DealerID] [int] NULL,
	[DocumentType] [nvarchar](100) NULL,
	[FileName] [nvarchar](255) NULL,
	[FilePath] [nvarchar](500) NULL,
	[UploadedDate] [datetime] NULL,
	[Comp_ID] [varchar](20) NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
