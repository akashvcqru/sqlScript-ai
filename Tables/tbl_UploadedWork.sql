SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_UploadedWork](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Comp_id] [nvarchar](50) NULL,
	[mobileno] [nvarchar](15) NULL,
	[imgpath] [nvarchar](500) NULL,
	[remark] [nvarchar](1000) NULL,
	[latitude] [nvarchar](50) NULL,
	[logitude] [nvarchar](50) NULL,
	[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_tbl_UploadedWork_CreatedDate] DEFAULT (getdate()),
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
