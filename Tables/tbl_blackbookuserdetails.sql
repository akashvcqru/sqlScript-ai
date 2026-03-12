/****** Object:  Table [dbo].[tbl_blackbookuserdetails]    Script Date: 3/2/2026 12:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tbl_blackbookuserdetails](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[Mobile_no] [varchar](13) NULL,
	[User_Name] [varchar](100) NULL,
	[Email] [nvarchar](100) NULL,
	[PinCode] [int] NULL,
	[City] [varchar](100) NULL,
	[State] [varchar](100) NULL,
	[Retailer_name] [varchar](100) NULL,
	[Book_name] [varchar](250) NULL,
	[Rating] [int] NULL,
	[Feedback] [varchar](max) NULL,
	[Enq_date] [datetime] NULL,
	[compid] [varchar](20) NULL,
	[IsDelete] [bit] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
