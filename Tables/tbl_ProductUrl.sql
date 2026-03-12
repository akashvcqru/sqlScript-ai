/****** Object:  Table [dbo].[tbl_ProductUrl]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_ProductUrl](
	[Row_ID] [int] IDENTITY(1,1) NOT NULL,
	[Prod_Url] [varchar](1000) NULL,
	[Name] [varchar](100) NULL,
	[Code] [varchar](100) NULL,
	[Click_Count] [varchar](100) NULL,
	[Remarks] [varchar](500) NULL,
	[IsActive] [int] NULL,
	[IsDelete] [int] NULL,
	[Created_by] [varchar](100) NULL,
	[Created_Date] [datetime] NULL,
	[Updated_by] [varchar](100) NULL,
	[Updated_Date] [datetime] NULL,
	[Latitude] [varchar](30) NULL,
	[Longitude] [varchar](30) NULL
) ON [PRIMARY]
GO
