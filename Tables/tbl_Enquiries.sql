/****** Object:  Table [dbo].[tbl_Enquiries]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_Enquiries](
	[Row_ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](100) NOT NULL,
	[Mobile_Number] [nvarchar](50) NOT NULL,
	[City] [varchar](50) NOT NULL,
	[Image_Url] [varchar](max) NULL,
	[Enquiry] [varchar](max) NULL,
	[Created_By] [varchar](50) NULL,
	[Created_Date] [datetime] NULL,
	[Updated_By] [varchar](50) NULL,
	[Updated_Date] [datetime] NULL,
	[IsActive] [int] NULL,
	[IsDelete] [int] NULL,
	[Remarks] [varchar](500) NULL,
	[Email_ID] [nvarchar](300) NULL,
	[Status] [int] NULL,
	[Calling_Status] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
